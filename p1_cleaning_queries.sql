/*===========================================================================================================================
Data Cleaning Script
Project: California Mental Health & Substance Use Data for ED & Inpatient Discharges by HPI Ranking (2020)
Author: Andrew "AJ" Owens
Purpose: Clean & audit raw data for nulls, blanks, outliers, duplicates, 
		 formatting issues, and anomalies
Dataset: 
California Health and Human Services Agency. (n.d.). Mental and Behavioral Health Diagnoses in Emergency Department 
and Inpatient Discharges. CHHS Open Data Portal. Retrieved [05/29/2025], 
from https://data.chhs.ca.gov/dataset/mental-and-behavioral-health-diagnoses-in-emergency-department-and-inpatient-discharges
                                           Last Updated: 6/12/2025 16:17:00 EST
==============================================================================================================================*/

SELECT *
FROM cali_mh_data_2020
LIMIT 10;
-- general exploratory query

SELECT * 
FROM cali_mh_data_2020
WHERE year IS NULL
	OR hpi_percentile_ranking IS NULL
	OR encounter_setting IS NULL
	OR category IS NULL
	OR category_description IS NULL
	OR diagnosis_group IS NULL
	OR residence IS NULL
	OR count IS NULL;
-- Checking for null values

SELECT *
FROM cali_mh_data_2020
WHERE hpi_percentile_ranking IN ('', ' ')
   OR encounter_setting IN ('', ' ')
   OR category IN ('', ' ')
   OR category_description IN ('', ' ')
   OR diagnosis_group IN ('', ' ')
   OR residence IN ('', ' ');
--Checking for blank values

SELECT *, COUNT(*)
FROM cali_mh_data_2020
GROUP BY year, hpi_percentile_ranking, encounter_setting, category, 
	category_description, diagnosis_group, residence, count
HAVING COUNT(*) > 1;
--Checking for duplicate rows

SELECT DISTINCT year
FROM cali_mh_data_2020;
-- Only 1 category should exist in this column, checking that this is true

SELECT DISTINCT hpi_percentile_ranking
FROM cali_mh_data_2020;
-- Only 4 categories should exist in this column, checking that this is true

SELECT DISTINCT encounter_setting
FROM cali_mh_data_2020;
-- Only 2 categories should exist in this column, checking that this is true

SELECT DISTINCT category
FROM cali_mh_data_2020;
-- Only 4 categories should exist in this column, checking that this is true

SELECT DISTINCT category_description
FROM cali_mh_data_2020;
-- Only 17 categories should exist in this column, checking that this is true

SELECT DISTINCT diagnosis_group
FROM cali_mh_data_2020;
-- Only 4 categories should exist in this column, checking that this is true

SELECT DISTINCT residence
FROM cali_mh_data_2020;
-- Only 2 categories should exist in this column, checking that this is true

SELECT *
FROM cali_mh_data_2020
WHERE count < 0;
--Checking for unexpected numeric values

SELECT 'hpi_percentile_ranking' AS column_name, 
       LENGTH(hpi_percentile_ranking) AS original_length, 
       LENGTH(TRIM(hpi_percentile_ranking)) AS trimmed_length
FROM cali_mh_data_2020
WHERE LENGTH(hpi_percentile_ranking) != LENGTH(TRIM(hpi_percentile_ranking))
UNION ALL
SELECT 'encounter_setting', 
       LENGTH(encounter_setting), 
       LENGTH(TRIM(encounter_setting))
FROM cali_mh_data_2020
WHERE LENGTH(encounter_setting) != LENGTH(TRIM(encounter_setting))
UNION ALL
SELECT 'category', 
       LENGTH(category), 
       LENGTH(TRIM(category))
FROM cali_mh_data_2020
WHERE LENGTH(category) != LENGTH(TRIM(category))
UNION ALL
SELECT 'category_description', 
       LENGTH(category_description), 
       LENGTH(TRIM(category_description))
FROM cali_mh_data_2020
WHERE LENGTH(category_description) != LENGTH(TRIM(category_description))
UNION ALL
SELECT 'diagnosis_group', 
       LENGTH(diagnosis_group), 
       LENGTH(TRIM(diagnosis_group))
FROM cali_mh_data_2020
WHERE LENGTH(diagnosis_group) != LENGTH(TRIM(diagnosis_group))
UNION ALL
SELECT 'residence', 
       LENGTH(residence), 
       LENGTH(TRIM(residence))
FROM cali_mh_data_2020
WHERE LENGTH(residence) != LENGTH(TRIM(residence));
--Checking each column and row for leading/trailing spaces

SELECT MIN(count) AS min, MAX(count) AS max, ROUND(AVG(count), 2) AS average, ROUND(STDDEV(count), 2) AS stand_dev
FROM cali_mh_data_2020;
-- Checking for outliers or any numbers that don't make sense in this column. MIN is 11 and is a big outlier. 

SELECT *
FROM cali_mh_data_2020
WHERE count < 100
ORDER BY count
/* Exploring the lowest values because the MIN is 11 and the AVG is 47,990.9. After referencing the data dictionary, I 
discovered a note that says "This product uses suppression of small numbers. Any count of diagnoses below 11 was
changed to 11 in the underlying dataset for de-identification purposes."*/
