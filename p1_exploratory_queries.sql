/*===========================================================================================================================
Exploratory Queries
Project: California Mental Health & Substance Use Data for ED & Inpatient Discharges by HPI Ranking (2020)
Author: Andrew "AJ" Owens
Purpose: Understanding the contents of the dataset to identify limitations and determine "fit" for answering the
	     stakeholder questions
Dataset: 
California Health and Human Services Agency. (n.d.). Mental and Behavioral Health Diagnoses in Emergency Department 
and Inpatient Discharges. CHHS Open Data Portal. Retrieved [05/29/2025], 
from https://data.chhs.ca.gov/dataset/mental-and-behavioral-health-diagnoses-in-emergency-department-and-inpatient-discharges
                                           Last Updated: 6/12/2025 16:17:00 EST
==============================================================================================================================*/

SELECT *
FROM cali_mh_data_2020
LIMIT 10;
-- General exploratory query

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'cali_mh_data_2020'
  AND table_schema = 'public';
--Schema and data types

-- Below: exploring all columns unique variables

SELECT DISTINCT hpi_percentile_ranking
FROM cali_mh_data_2020;

SELECT DISTINCT encounter_setting
FROM cali_mh_data_2020;

SELECT DISTINCT category
FROM cali_mh_data_2020;

SELECT DISTINCT category, category_description
FROM cali_mh_data_2020
ORDER BY category, category_description;
--category and category_description are related as one is a subset of the other. Seeing which variables are associated

SELECT DISTINCT diagnosis_group
FROM cali_mh_data_2020

SELECT DISTINCT residence
FROM cali_mh_data_2020;