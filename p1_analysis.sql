/*===========================================================================================================================
Data Analysis
Project: California Mental Health & Substance Use Data for ED & Inpatient Discharges by HPI Ranking (2020)
Author: Andrew "AJ" Owens
Purpose: Answering questions related to the project to later visualize 
Dataset: 
California Health and Human Services Agency. (n.d.). Mental and Behavioral Health Diagnoses in Emergency Department 
and Inpatient Discharges. CHHS Open Data Portal. Retrieved [05/29/2025], 
from https://data.chhs.ca.gov/dataset/mental-and-behavioral-health-diagnoses-in-emergency-department-and-inpatient-discharges
                                         Last Updated: 6/12/2025 16:17:00 EST
==============================================================================================================================*/

/*=====================================================================================================
                              Questions for Analysis
1. How do diagnosis counts differ by HPI percentile?
2. Is each HPI group more likely to use the ED or inpatient setting? 
3. What is the difference in proportion of ED vs. IP admissions by HPI group?
4. What are the diagnosis counts by sex and diagnosis group? 
5. How does diagnosis count vary by race/ethnicity?
6. What is the age distribution of diagnoses? 
7. What percentage of each diagnosis group is homeless vs. not homeless?
8. What is the diagnostic profile of homeless vs. not homeless patients relative to one another?
9. Are homeless, uninsured patients more likely to use the ED relative to homeless, insured patients?
10. What is the payer mix across encounter settings & residence status?
11. What is the payer distribution within each diagnosis group?
12. How does age distribution of diagnoses differ between homeless and non-homeless patients?
======================================================================================================*/

/*===================================================
1. How do diagnosis counts differ by HPI percentile? 
=====================================================*/
-- hpi_totals CTE to create a table grouping the hpi_percentiles in order to execute the LAG function below to compare
WITH hpi_totals AS (
  SELECT
    hpi_percentile_ranking,
    SUM(count) AS dx_by_hpi
  FROM cali_mh_data_2020
  GROUP BY hpi_percentile_ranking
),
/*parsed_hpi CTE to explicitly split hpi_percentile_ranking into part numeric value to ensure the ORDER BY functions appropriately.
The query just so happens to work without it, but this wouldn't always be the case if the data were different */
parsed_hpi AS (
  SELECT
    hpi_percentile_ranking,
    dx_by_hpi,
    CAST(split_part(split_part(hpi_percentile_ranking, ' ', 1), '-', 1) AS NUMERIC) AS hpi_sort_key
  FROM hpi_totals
)
-- final output to compare # of diagnoses by hpi percentile rank ordered by hpi_percentile_ranking
-- includes % of total diagnoses and difference from previous group
SELECT
  hpi_percentile_ranking,
  dx_by_hpi,
  ROUND(100.0 * dx_by_hpi / SUM(dx_by_hpi) OVER (), 2) AS percent_of_total,
  LAG(dx_by_hpi) OVER (ORDER BY hpi_sort_key) AS previous_dx_by_hpi,
  dx_by_hpi - LAG(dx_by_hpi) OVER (ORDER BY hpi_sort_key) AS difference
FROM parsed_hpi
ORDER BY hpi_sort_key;


/*==================================================================================
2. Is each HPI group more likely to use the ED or inpatient setting? 
3. What is the difference in proportion of ED vs. IP admissions by HPI group? 
===================================================================================*/
WITH
-- ED Visit encounters by hpi percentile
	ed_numbers AS(
		SELECT 
		  hpi_percentile_ranking,
		  SUM(CASE WHEN encounter_setting = 'ED Visit' THEN count ELSE 0 END) AS ed_total
		FROM cali_mh_data_2020
		WHERE encounter_setting = 'ED Visit'
		GROUP BY hpi_percentile_ranking, encounter_setting),
-- inpatient encounters by hpi percentile
	ip_numbers AS(
		SELECT 
		  hpi_percentile_ranking,
		  SUM(CASE WHEN encounter_setting = 'Inpatient' THEN count ELSE 0 END) AS inpatient_total
		FROM cali_mh_data_2020
		WHERE encounter_setting = 'Inpatient'
		GROUP BY hpi_percentile_ranking, encounter_setting)
-- Compares each hpi percentile group and determines whether there are more inpatient or ed visits in that group
-- Examines the percentage difference between ed and inpatient visits HPI
SELECT 
	e.hpi_percentile_ranking,
	CASE 
		WHEN e.ed_total > i.inpatient_total THEN 'ED Visit'
		WHEN e.ed_total < i.inpatient_total THEN 'Inpatient'
		ELSE 'Equal Use'
	END AS most_used,
	e.ed_total,
	i.inpatient_total, 
	ROUND((e.ed_total::numeric / NULLIF(e.ed_total + i.inpatient_total, 0)) * 100, 2) AS percent_ed_visits,
	ROUND((i.inpatient_total::numeric / NULLIF(e.ed_total + i.inpatient_total, 0)) * 100, 2) AS percent_inpatient_visits
FROM ed_numbers e
JOIN ip_numbers i 
ON e.hpi_percentile_ranking = i.hpi_percentile_ranking
ORDER BY e.hpi_percentile_ranking;


/*==========================================================
4. What are the diagnosis counts by sex and diagnosis group? 
===========================================================*/
WITH 
-- CTEs for count of diagnoses by diagnosis group for male & female
	female AS
		(SELECT
			diagnosis_group,
			SUM(count) AS female_total
		FROM cali_mh_data_2020
		WHERE category_description = 'Female'
		GROUP BY diagnosis_group),
	male AS
		(SELECT
			diagnosis_group,
			SUM(count) AS male_total
		FROM cali_mh_data_2020
		WHERE category_description = 'Male'
		GROUP BY diagnosis_group)
-- gives female and male total dx by dx group & percentages
SELECT
	f.diagnosis_group,
	f.female_total,
	ROUND((female_total::numeric/(female_total + male_total) * 100), 2) AS female_percent,
	m.male_total,
	ROUND((male_total::numeric/(female_total + male_total) * 100), 2) AS male_percent
FROM female AS f
JOIN male AS m
ON f.diagnosis_group = m.diagnosis_group;


/*===================================================
5. How does diagnosis count vary by race/ethnicity?
===================================================*/
-- Using FILTER/Case for cleaner syntax in race/ethnicity breakdown versus using CTE for sex
-- Using a combination of filter and case to demonstrate knowledge of alternate aggregation strategies
-- table to show race/ethnicity breakdown of diagnosis groups & percentages
SELECT
	diagnosis_group,
	SUM(count) FILTER (WHERE category_description = 'American Indian/Alaska Native') AS ai_an_total,
	SUM(count) FILTER (WHERE category_description = 'Asian/Pacific Islander') AS asian_pi_total,
	SUM(count) FILTER (WHERE category_description = 'Black') AS black_total,
	SUM(count) FILTER (WHERE category_description = 'Hispanic') AS hispanic_total,
	SUM(count) FILTER (WHERE category_description = 'Other Race/Ethnicity') AS other_total,
	SUM(count) FILTER (WHERE category_description = 'White') AS white_total,
	ROUND(SUM(CASE WHEN category_description = 'American Indian/Alaska Native' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS ai_an_percent,
	ROUND(SUM(CASE WHEN category_description = 'Asian/Pacific Islander' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS asian_pi_percent,
	ROUND(SUM(CASE WHEN category_description = 'Black' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS black_percent,
	ROUND(SUM(CASE WHEN category_description = 'Hispanic' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS hispanic_percent,
	ROUND(SUM(CASE WHEN category_description = 'Other Race/Ethnicity' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS other_percent,
	ROUND(SUM(CASE WHEN category_description = 'White' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS white_percent
FROM cali_mh_data_2020
WHERE category = 'Race/Ethnicity Group'
GROUP BY diagnosis_group
ORDER BY diagnosis_group;


/*============================================
6. What is the age distribution of diagnoses? 
============================================*/
--breakdown of diagnosis groups by age
SELECT
	diagnosis_group,
	SUM(count) FILTER (WHERE category_description = '0 to 18') AS age_0_18_total,
	SUM(count) FILTER (WHERE category_description = '19 to 39') AS age_19_39_total,
	SUM(count) FILTER (WHERE category_description = '40 to 59') AS age_40_59_total,
	SUM(count) FILTER (WHERE category_description = '60+') AS age_60_plus_total,
	ROUND(SUM(CASE WHEN category_description = '0 to 18' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS age_0_18_percent,
	ROUND(SUM(CASE WHEN category_description = '19 to 39' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS age_19_39_percent,
	ROUND(SUM(CASE WHEN category_description = '40 to 59' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS age_40_59_percent,
	ROUND(SUM(CASE WHEN category_description = '60+' THEN count ELSE 0 END)::numeric / SUM(count) * 100, 2) AS age_60_plus_percent
FROM cali_mh_data_2020
WHERE category = 'Age Group'
GROUP BY diagnosis_group
ORDER BY diagnosis_group;


/*========================================================================
7. What percentage of each diagnosis group is homeless vs. not homeless?
=========================================================================*/
-- CTEs to add up the amount of diagnoses per diagnosis group for homeless and not homeless categories
WITH
	homeless_count AS(
		SELECT diagnosis_group, SUM(count::int) AS homeless_dx_count
		FROM cali_mh_data_2020
		WHERE residence = 'Homeless'
		GROUP BY diagnosis_group),
	not_homeless_count AS(	
		SELECT diagnosis_group, SUM(count::int) AS not_homeless_dx_count
		FROM cali_mh_data_2020
		WHERE residence = 'Not Homeless'
		GROUP BY diagnosis_group)
-- Produces sum of diagnoses and percentages by homeless and not homeless by dx categories
SELECT 
	hc.diagnosis_group, 
	hc.homeless_dx_count, 
	nhc.not_homeless_dx_count,
	ROUND(hc.homeless_dx_count::numeric/(hc.homeless_dx_count + nhc.not_homeless_dx_count) * 100,2) AS homeless_percentage,
	ROUND(nhc.not_homeless_dx_count::numeric/(hc.homeless_dx_count + nhc.not_homeless_dx_count) * 100,2) AS not_homeless_percentage
FROM homeless_count AS hc
JOIN not_homeless_count AS nhc
	ON hc.diagnosis_group = nhc.diagnosis_group;


/*==============================================================================================
8. What is the diagnostic profile of homeless vs. not homeless patients relative to one another?
===============================================================================================*/
WITH 
--CTE to add up the dx counts grouped by residence status (homeless v. not homeless) & the 4 dx groups
	base AS(
		SELECT residence, diagnosis_group, SUM(count::int) AS dx_count
		FROM cali_mh_data_2020
		GROUP BY residence, diagnosis_group),
--CTE to find the total dx counts for homeless & not homeless residence groups 		
	totals AS (
		SELECT residence, SUM(dx_count) AS total_dx
		FROM base
		GROUP BY residence)
--breaks down each residence group by dx group and provides the counts and percentages of each residence group 
SELECT
	b.residence,
	b.diagnosis_group,
	b.dx_count,
	t.total_dx,
	ROUND((b.dx_count::numeric / t.total_dx) * 100, 2) AS dx_percent_within_group
FROM base AS b
JOIN totals AS t 
	ON b.residence = t.residence
ORDER BY b.residence, diagnosis_group;

/*=====================================================================================================
9. Are homeless, uninsured patients more likely to use the ED relative to homeless, insured patients?
=====================================================================================================*/
WITH
--CTEs to sum the amount of residence = 'Homeless' folks are insured v. uninsured. 
--For simplicity, 'Other Payer' is lumped into insured as there is some sort of payer source, albeit an uncommon one vs someone with no coverage whatsoever
	homeless_insured AS(
		SELECT encounter_setting, SUM(count) AS insured_count
		FROM cali_mh_data_2020
		WHERE category_description IN ('Medi-Cal', 'Medicare', 'Other Payer', 'Private Coverage')
			AND residence = 'Homeless'
		GROUP BY encounter_setting),
	homeless_uninsured AS(
		SELECT encounter_setting, SUM(count) AS uninsured_count
		FROM cali_mh_data_2020
		WHERE category_description = 'Uninsured'
			AND residence = 'Homeless'
		GROUP BY encounter_setting),
--CTE to add up the combined totals	of both groups inpatient + ed visit in order to examine proportionality in the output
	totals AS (
    	SELECT
	      (SELECT SUM(count)
	       FROM cali_mh_data_2020
	       WHERE category_description IN ('Medi-Cal', 'Medicare', 'Other Payer', 'Private Coverage')
	         AND residence = 'Homeless') AS total_insured,
	      (SELECT SUM(count)
	       FROM cali_mh_data_2020
	       WHERE category_description = 'Uninsured'
	         AND residence = 'Homeless') AS total_uninsured)
-- examines the proportionality of ED visits for homeless patients based on whether they are insured or uninsured
--inpatient proportionality also included in order to do the math for the comparison
--you could use this query to answer the question with Inpatient encounter proportionality as well
SELECT
	hi.encounter_setting,
	hi.insured_count,
	hui.uninsured_count,
	ROUND((hi.insured_count::numeric / t.total_insured) * 100, 2) AS percent_insured_visits,
	ROUND((hui.uninsured_count::numeric / t.total_uninsured) * 100, 2) AS percent_uninsured_visits
FROM homeless_insured AS hi
JOIN homeless_uninsured AS hui ON hi.encounter_setting = hui.encounter_setting
CROSS JOIN totals AS t
ORDER BY hi.encounter_setting;
-- It is important to note that this data is based on encounter counts not individual patients. The query addresses visit proportions rather than patients


/*======================================================================
10. What is the payer mix across encounter settings & residence status?
=======================================================================*/
--outputs the 5 different types of expected payer and provides counts and percentages grouped by residence status & encounter setting. 
--Ranks payers 1-5 for each group
SELECT
  residence,
  encounter_setting,
  category_description,
  SUM(count) AS insured_count,
  ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (PARTITION BY residence, encounter_setting), 2) AS payer_percentage, 
  RANK() OVER (PARTITION BY residence, encounter_setting ORDER BY SUM(count) DESC) AS payer_rank
FROM cali_mh_data_2020
WHERE category = 'Expected Payer'
GROUP BY residence, encounter_setting, category_description
ORDER BY residence, encounter_setting, payer_rank;


/*==============================================================
11. What is the payer distribution within each diagnosis group? 
===============================================================*/
--outputs the 5 different types of expected payer and provides counts and percentages grouped by diagnosis group
--Ranks payers 1-5 for each group
SELECT
  diagnosis_group,
  category_description AS expected_payer,
  SUM(count) AS insured_count,
  ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (PARTITION BY diagnosis_group), 2) AS payer_percentage,
  RANK() OVER (PARTITION BY diagnosis_group ORDER BY SUM(count) DESC) AS payer_rank
FROM cali_mh_data_2020
WHERE category = 'Expected Payer'
GROUP BY diagnosis_group, category_description
ORDER BY diagnosis_group, payer_rank;


/*=============================================================================================
12. How does age distribution of diagnoses differ between homeless and non-homeless patients?
=============================================================================================*/
--Examines the distribution of diagnoses by age group and groups by residence 
--ranks 1-4
SELECT
  residence,
  category_description AS age_group,
  SUM(count) AS diagnosis_count,
  ROUND(SUM(count) * 100.0 / SUM(SUM(count)) OVER (PARTITION BY residence), 2) AS age_group_percentage,
  RANK() OVER (PARTITION BY residence ORDER BY SUM(count) DESC) AS age_group_rank
FROM cali_mh_data_2020
WHERE category = 'Age Group'
GROUP BY residence, category_description
ORDER BY residence, age_group_rank;






