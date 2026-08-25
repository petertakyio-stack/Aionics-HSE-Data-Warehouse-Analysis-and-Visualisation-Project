/*
===============================================================================
Silver Data Quality Checks: silver.event_records
===============================================================================

Purpose:
    Validate that the Silver event_records table conforms to the cleaning
    rules and HSE business logic applied during transformation.

Expected Result:
    Unless otherwise stated, each exception query should return 0 rows.
===============================================================================
*/


-- 1. ROW-COUNT RECONCILIATION
-- Business Rule: Silver should contain every Bronze record with a valid
-- event_date_id. Records with invalid dates are intentionally excluded.

SELECT
    (SELECT COUNT(*)
     FROM bronze.event_records
     WHERE COALESCE(
        TRY_CONVERT(DATE,TRIM(event_date_id),112),
        TRY_CONVERT(DATE,TRIM(event_date_id),23),
        TRY_CONVERT(DATE,TRIM(event_date_id),111),
        TRY_CONVERT(DATE,TRIM(event_date_id),103)
     ) IS NOT NULL) AS expected_rows,
    (SELECT COUNT(*) FROM silver.event_records) AS silver_rows;


-- 2. EVENT RECORD ID UNIQUENESS
-- Business Rule: event_record_id uniquely identifies each source event record.

SELECT event_record_id,COUNT(*) AS occurrence
FROM silver.event_records
GROUP BY event_record_id
HAVING COUNT(*)>1 OR event_record_id IS NULL;


-- 3. EVENT ID UNIQUENESS
-- Business Rule: recreated event_id must uniquely identify each retained event.

SELECT event_id,COUNT(*) AS occurrence
FROM silver.event_records
GROUP BY event_id
HAVING COUNT(*)>1 OR event_id IS NULL;


-- 4. EVENT ID FORMAT
-- Business Rule: event_id must follow HSE-YYYY-######.

SELECT event_record_id,event_id
FROM silver.event_records
WHERE LEN(event_id) != 15
   OR event_id NOT LIKE 'HSE-[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]';


-- 5. EVENT ID YEAR AND RECORD NUMBER
-- Business Rule:
--   - event_id year must equal the year in event_date_id.
--   - final 6 digits must correspond to event_record_id.

SELECT event_record_id,event_id,event_date_id
FROM silver.event_records
WHERE SUBSTRING(event_id,5,4) != LEFT(CAST(event_date_id AS VARCHAR(8)),4)
   OR CAST(RIGHT(event_id,6) AS INT) != event_record_id;


-- 6. CALENDAR INTEGRITY
-- Business Rule: every event_date_id must have a corresponding calendar date.

SELECT e.event_record_id,e.event_date_id
FROM silver.event_records e
LEFT JOIN silver.calendar c ON e.event_date_id=c.date_id
WHERE c.date_id IS NULL;


-- 7. FOREIGN-KEY INTEGRITY
-- Business Rule: event references must point to valid source entities.
-- Replace bronze with silver once the corresponding Silver tables are loaded.

SELECT
    e.event_record_id,
    CASE WHEN s.site_id IS NULL THEN e.site_id END AS invalid_site_id,
    CASE WHEN p.person_id IS NULL THEN e.person_id END AS invalid_person_id,
    CASE WHEN eq.equipment_id IS NULL THEN e.equipment_id END AS invalid_equipment_id,
    CASE WHEN a.activity_id IS NULL THEN e.activity_id END AS invalid_activity_id,
    CASE WHEN c.cause_id IS NULL THEN e.cause_id END AS invalid_cause_id
FROM silver.event_records e
LEFT JOIN bronze.sites s ON e.site_id=s.site_id
LEFT JOIN bronze.personnel p ON e.person_id=p.person_id
LEFT JOIN bronze.equipment eq ON e.equipment_id=eq.equipment_id
LEFT JOIN bronze.work_activities a ON e.activity_id=a.activity_id
LEFT JOIN bronze.cause_reference c ON e.cause_id=c.cause_id
WHERE s.site_id IS NULL
   OR p.person_id IS NULL
   OR eq.equipment_id IS NULL
   OR a.activity_id IS NULL
   OR c.cause_id IS NULL;


-- 8. EVENT TYPE STANDARDIZATION
-- Business Rule: no source aliases used in cleaning should remain in Silver.

SELECT DISTINCT event_type
FROM silver.event_records
WHERE LOWER(TRIM(event_type)) IN (
    'fac','lti','mtc','nearmiss','near-miss',
    'spill release','spill/release','vehicle accident'
);


-- 9. SEVERITY / PROCESS SAFETY VALUES
-- Business Rule: categorical values must remain within the approved domains.

SELECT DISTINCT severity_class
FROM silver.event_records
WHERE severity_class NOT IN (
    'Low','Moderate','High','Major','High Potential','Catastrophic'
);

SELECT DISTINCT process_safety_tier
FROM silver.event_records
WHERE process_safety_tier NOT IN ('Tier 1','Tier 2','Tier 3','N/A');


-- 10. RECORDABLE FLAG DOMAIN
-- Business Rule: recordable_flag is binary.

SELECT *
FROM silver.event_records
WHERE recordable_flag NOT IN (0,1) OR recordable_flag IS NULL;


-- 11. RECORDABLE FLAG LOGIC
-- Business Rule: Fatality, Lost Time Injury and Medical Treatment Case are
-- recordable. A positive fatality or restricted-work count is also recordable.

SELECT event_record_id,event_type,fatality_count,restricted_days,recordable_flag
FROM silver.event_records
WHERE recordable_flag != 
    CASE
        WHEN event_type IN ('Fatality','Lost Time Injury','Medical Treatment Case') THEN 1
        WHEN fatality_count>0 THEN 1
        WHEN restricted_days>0 THEN 1
        ELSE 0
    END;


-- 12. LOST-TIME FLAG
-- Business Rule: the transformation defines Lost Time Injury as the event type
-- that receives lost_time_flag = 1.

SELECT event_record_id,event_type,lost_time_flag
FROM silver.event_records
WHERE lost_time_flag != 
    CASE WHEN event_type='Lost Time Injury' THEN 1 ELSE 0 END;


-- 13. FATALITY COUNT
-- Business Rules:
--   - Fatality events must have at least one fatality.
--   - First Aid, Near Miss and Property Damage must have fatality_count = 0.
--   - Negative fatality counts are impossible.

SELECT event_record_id,event_type,fatality_count
FROM silver.event_records
WHERE fatality_count<0
   OR (event_type='Fatality' AND (fatality_count IS NULL OR fatality_count<1))
   OR (event_type IN ('First Aid Case','Near Miss','Property Damage') AND fatality_count != 0);


-- 14. DAYS LOST
-- Business Rules:
--   - Days lost cannot be negative.
--   - Values are capped at 180.
--   - Near Miss and First Aid cannot have positive days lost.
--   - Invalid LTI day counts are represented as NULL rather than fabricated.

SELECT event_record_id,event_type,days_lost
FROM silver.event_records
WHERE days_lost<0
   OR days_lost>180
   OR (event_type IN ('Near Miss','First Aid Case') AND days_lost>0)
   OR (event_type='Lost Time Injury' AND days_lost=0);


-- 15. RESTRICTED DAYS
-- Business Rule: restricted days are non-negative counts.
-- N/A or unusable source values may become NULL.

SELECT event_record_id,event_type,restricted_days
FROM silver.event_records
WHERE restricted_days<0;


-- 16. NUMERIC HSE MEASURES
-- Business Rule: volume, cost and downtime cannot be negative.

SELECT event_record_id,spill_volume_l,incident_cost_usd,downtime_hours
FROM silver.event_records
WHERE spill_volume_l<0
   OR incident_cost_usd<0
   OR downtime_hours<0;


-- 17. REGULATOR REPORTABLE FLAG
-- Business Rule: regulator_reportable_flag is already logically correct in
-- the regenerated source and must remain a binary value in Silver.

SELECT *
FROM silver.event_records
WHERE regulator_reportable_flag NOT IN (0,1)
   OR regulator_reportable_flag IS NULL;


-- 18. REGULATOR REPORTING LOGIC
-- Practice Business Rule:
-- Fatality, Lost Time Injury, Spill / Release, Fire / Explosion,
-- Environmental Non-Conformance, or Tier 1 events are regulator-reportable.

SELECT event_record_id,event_type,process_safety_tier,regulator_reportable_flag
FROM silver.event_records
WHERE regulator_reportable_flag != 
    CASE
        WHEN event_type IN ('Fatality','Lost Time Injury','Spill / Release','Fire / Explosion','Environmental Non-Conformance') THEN 1
        WHEN process_safety_tier='Tier 1' THEN 1
        ELSE 0
    END;


-- 19. DWH CREATION DATE
-- Business Rule: every Silver record must have an ETL creation timestamp.

SELECT *
FROM silver.event_records
WHERE dwh_create_date IS NULL;



/*
===============================================================================
Data Quality Check: bronze.calendar
===============================================================================
Purpose:
    Profiles and cleans the calendar data before loading it into Silver.

Checks:
    - Duplicate/NULL date_id
    - Mismatch between date_id and full_date
    - day_name inconsistencies
    - Invalid day_of_week and is_weekend values

Cleaning:
    - Deduplicates date_id
    - Rebuilds full_date from date_id
    - Derives all calendar attributes from the cleaned date
===============================================================================
*/

SET DATEFIRST 1;

-- 1. Check duplicate and NULL date_id
SELECT date_id, COUNT(*) AS occurrence
FROM silver.calendar
GROUP BY date_id
HAVING COUNT(*) > 1 OR date_id IS NULL;

-- 2. Check date_id against full_date
SELECT date_id, full_date
FROM silver.calendar
WHERE CAST(CAST(date_id AS NVARCHAR) AS DATE) != full_date;

-- 3. Check day_name quality
SELECT DISTINCT day_name
FROM silver.calendar
WHERE TRIM(day_name) != day_name;

SELECT DISTINCT day_name
FROM silver.calendar
ORDER BY day_name;

-- 4. Check day_of_week
SELECT day_of_week
FROM silver.calendar
WHERE day_of_week NOT BETWEEN 1 AND 7;

SELECT full_date,
       DATEPART(weekday, full_date) AS expected_day_of_week,
       day_of_week
FROM silver.calendar
WHERE DATEPART(weekday, full_date) != day_of_week;

-- 5. Check is_weekend
SELECT DISTINCT is_weekend
FROM silver.calendar
ORDER BY is_weekend;

SELECT *
FROM silver.calendar
WHERE is_weekend NOT IN (0,1);

/*
===============================================================================
Silver Data Quality Checks: silver.cause_reference
===============================================================================

Purpose:
    Validate that the Silver cause_reference table conforms to the agreed
    cleansing rules and HSE business logic.

Checks:
    - Primary key uniqueness and completeness
    - NULL and blank descriptive values
    - Leading and trailing spaces
    - Standardised sentence casing
    - Binary factor flag values
    - Logical consistency of HSE factor classifications

Business Rules:
    - Each cause_id must uniquely identify one cause record.
    - Cause descriptions and categories must contain usable values.
    - Descriptive text must be trimmed and begin with a capital letter.
    - Recognised abbreviations such as PPE and LOTO may remain uppercase.
    - Factor flags must contain only 0 or 1.
    - Human, equipment and management-system factors are not mutually
      exclusive; more than one factor may apply to the same cause.
    - Unknown causes may legitimately have all factor flags set to 0.

Expected Result:
    Unless otherwise stated, exception queries should return 0 rows.

===============================================================================
*/

-- 1. Primary key duplicate check
-- Business Rule: Each cause must have one unique cause_id.
SELECT cause_id,COUNT(*) AS occurrence
FROM silver.cause_reference
GROUP BY cause_id
HAVING COUNT(*)>1;
-- Expected: no results


-- 2. Primary key NULL check
-- Business Rule: Every cause record must have a valid cause_id.
SELECT *
FROM silver.cause_reference
WHERE cause_id IS NULL;
-- Expected: no results


-- 3. Check for NULL or blank descriptive values
-- Business Rule: Cause categories and descriptions must contain usable values.
SELECT *
FROM silver.cause_reference
WHERE immediate_cause_category IS NULL OR TRIM(immediate_cause_category)=''
   OR immediate_cause IS NULL OR TRIM(immediate_cause)=''
   OR root_cause_category IS NULL OR TRIM(root_cause_category)=''
   OR root_cause IS NULL OR TRIM(root_cause)='';
-- Expected: no results


-- 4. Check for leading and trailing spaces
-- Business Rule: All descriptive values must be trimmed in Silver.
SELECT *
FROM silver.cause_reference
WHERE immediate_cause_category != TRIM(immediate_cause_category)
   OR immediate_cause != TRIM(immediate_cause)
   OR root_cause_category != TRIM(root_cause_category)
   OR root_cause != TRIM(root_cause);
-- Expected: no results

-- 5. Check factor flag domains
-- Business Rule: Factor flags must be binary: 0 = No, 1 = Yes.
SELECT *
FROM silver.cause_reference
WHERE human_factor_flag NOT IN (0,1) OR human_factor_flag IS NULL
   OR equipment_factor_flag NOT IN (0,1) OR equipment_factor_flag IS NULL
   OR management_system_factor_flag NOT IN (0,1) OR management_system_factor_flag IS NULL;
-- Expected: no results


-- 6. Review HSE factor classification logic
-- Business Rule: Factor flags should reasonably reflect the immediate and
-- root causes. Multiple factors may apply to the same cause.
SELECT
    cause_id,
    immediate_cause_category,
    immediate_cause,
    root_cause_category,
    root_cause,
    human_factor_flag,
    equipment_factor_flag,
    management_system_factor_flag
FROM silver.cause_reference
ORDER BY immediate_cause_category,immediate_cause;
-- Expected: classifications should remain logically consistent.


-- 7. Check records with no identified contributing factor
-- Business Rule: Unknown causes may legitimately have all flags = 0.
-- Other records with all flags = 0 should be reviewed.
SELECT *
FROM silver.cause_reference
WHERE human_factor_flag=0
  AND equipment_factor_flag=0
  AND management_system_factor_flag=0
  AND root_cause_category != 'Unknown';
-- Expected: review any returned records.


/*
===============================================================================
Silver Data Quality Checks: silver.equipment
===============================================================================

Purpose:
    Validate that the Silver equipment table conforms to the agreed
    cleansing rules and equipment business logic.

Checks:
    - Primary key and asset ID uniqueness
    - NULL and blank values
    - Leading and trailing spaces
    - Asset ID format and relationship to equipment_id
    - Asset/site relationship
    - Controlled categorical values
    - Installation year and equipment age validity
    - Home-site referential integrity
    - Unknown-member consistency

Business Rules:
    - equipment_id must uniquely identify each equipment record.
    - asset_id must uniquely identify each known asset.
    - Known asset IDs follow the format AST-##-#####.
    - The last five digits of asset_id correspond to equipment_id.
    - The site number embedded in asset_id corresponds to home_site_id.
    - install_year = 0 is converted to NULL in Silver.
    - asset_age_years is NULL only for the Unknown equipment member;
      zero remains valid for newly installed equipment.
    - equipment_id = 0 is retained as the designated Unknown equipment member.
    - Controlled categorical values must use the agreed casing.

Expected Result:
    Unless otherwise stated, exception queries should return 0 rows.
===============================================================================
*/

USE AionicsDataWarehouse;
GO

/* 1. Primary key and asset ID uniqueness */
SELECT 
    equipment_id,
    COUNT(*) AS occurrence
FROM silver.equipment
GROUP BY equipment_id
HAVING COUNT(*)>1 OR equipment_id IS NULL;

SELECT 
    asset_id,
    COUNT(*) AS occurrence
FROM silver.equipment
GROUP BY asset_id
HAVING COUNT(*)>1 OR asset_id IS NULL OR TRIM(asset_id)='';


/* 2. NULL/blank values and unwanted spaces */
SELECT 
    *
FROM silver.equipment
WHERE asset_type IS NULL OR TRIM(asset_type)=''
   OR criticality IS NULL OR TRIM(criticality)=''
   OR maintenance_status IS NULL OR TRIM(maintenance_status)=''
   OR inspection_status IS NULL OR TRIM(inspection_status)=''
   OR asset_id != TRIM(asset_id)
   OR asset_type != TRIM(asset_type)
   OR criticality != TRIM(criticality)
   OR maintenance_status != TRIM(maintenance_status)
   OR inspection_status != TRIM(inspection_status);


/* 3. Asset ID format and relationship to equipment_id */
SELECT 
    equipment_id,
    asset_id
FROM silver.equipment
WHERE equipment_id != 0
  AND (
        LEN(asset_id) != 12
        OR LEFT(asset_id,4) != 'AST-'
        OR SUBSTRING(asset_id,7,1) != '-'
        OR TRY_CAST(SUBSTRING(asset_id,5,2) AS INT) IS NULL
        OR TRY_CAST(RIGHT(asset_id,5) AS INT) IS NULL
        OR equipment_id != TRY_CAST(RIGHT(asset_id,5) AS INT)
      );


/* 4. Site embedded in asset_id must match home_site_id */
SELECT 
    equipment_id,
    asset_id,
    home_site_id
FROM silver.equipment
WHERE equipment_id != 0
  AND TRY_CAST(SUBSTRING(asset_id,5,2) AS INT) != home_site_id;


/* 5. Controlled category validation */
SELECT *
FROM silver.equipment
WHERE criticality NOT IN ('A - Critical', 'B - Important', 'C - General', 'Unknown')
   OR maintenance_status NOT IN ('Good','Monitor','Maintenance Due','Overdue','Unknown')
   OR inspection_status NOT IN ('In Date','Due within 30 days','Overdue','Not Applicable','Unknown');


/* 6. Installation year and equipment age validity */
SELECT equipment_id,install_year,asset_age_years
FROM silver.equipment
WHERE equipment_id != 0
  AND (
        install_year IS NULL
        OR install_year<1900
        OR install_year>YEAR(GETDATE())
        OR asset_age_years IS NULL
        OR asset_age_years<0
        OR asset_age_years != YEAR(GETDATE())-install_year
      );


/* 7. Home-site referential integrity */
SELECT e.equipment_id,e.asset_id,e.home_site_id
FROM silver.equipment e
LEFT JOIN silver.sites s
    ON e.home_site_id=s.site_id
WHERE e.equipment_id != 0
  AND s.site_id IS NULL;


/* 8. Validate designated Unknown equipment member */
SELECT *
FROM silver.equipment
WHERE equipment_id=0
  AND (
        asset_id != 'UNKNOWN'
        OR asset_type != 'Unknown'
        OR criticality != 'Unknown'
        OR maintenance_status != 'Unknown'
        OR inspection_status != 'Unknown'
        OR install_year IS NOT NULL
        OR asset_age_years IS NOT NULL
        OR home_site_id IS NOT NULL
      );


/* 9. Confirm exactly one Unknown equipment member */
SELECT COUNT(*) AS unknown_member_count
FROM silver.equipment
WHERE equipment_id=0;
-- Expected result: 1


/* 10. Review available asset types */
SELECT DISTINCT asset_type
FROM silver.equipment
ORDER BY asset_type;
-- Review only; asset_type contains multiple legitimate equipment categories.

/*
===============================================================================
Silver Data Quality Checks: silver.personnel
===============================================================================

Purpose:
    Validate that the Silver personnel table conforms to the agreed
    cleansing rules and personnel business logic.

Checks:
    - Primary key and employee ID uniqueness
    - NULL and blank values
    - Leading and trailing spaces
    - Employee ID format and relationship to person_id
    - Employment type and employee ID consistency
    - Contractor-company business rules
    - Department standardisation
    - Age-band validity
    - Years-of-experience validity
    - Training-status standardisation
    - Unknown-member consistency

Business Rules:
    - person_id must uniquely identify each personnel record.
    - employee_id must uniquely identify each known person.
    - Employees use EMP IDs; contractors use CTR IDs.
    - The numeric portion of employee_id must correspond to person_id.
    - Contractor company is applicable only to contractors.
    - age_band_code is treated as a categorical code, not a numeric measure.
    - years_experience cannot be negative.
    - person_id = 0 is retained as the designated Unknown personnel member.

Expected Result:
    Unless otherwise stated, exception queries should return 0 rows.
===============================================================================
*/

-- 1. Primary key NULL or duplicate
SELECT person_id,COUNT(*) AS occurrence
FROM silver.personnel
GROUP BY person_id
HAVING COUNT(*)>1 OR person_id IS NULL;


-- 2. Employee ID NULL, blank or duplicate
SELECT employee_id,COUNT(*) AS occurrence
FROM silver.personnel
GROUP BY employee_id
HAVING COUNT(*)>1
    OR employee_id IS NULL
    OR TRIM(employee_id)='';


-- 3. NULL or blank required descriptive fields
SELECT *
FROM silver.personnel
WHERE employment_type IS NULL OR TRIM(employment_type)=''
   OR department IS NULL OR TRIM(department)=''
   OR job_title IS NULL OR TRIM(job_title)=''
   OR age_band_code IS NULL OR TRIM(age_band_code)=''
   OR training_status IS NULL OR TRIM(training_status)='';


-- 4. Leading or trailing spaces
SELECT *
FROM silver.personnel
WHERE employee_id != TRIM(employee_id)
   OR employment_type != TRIM(employment_type)
   OR contractor_company != TRIM(contractor_company)
   OR department != TRIM(department)
   OR job_title != TRIM(job_title)
   OR age_band_code != TRIM(age_band_code)
   OR training_status != TRIM(training_status);


-- 5. person_id must match numeric suffix of employee_id
-- Exclude the designated Unknown member
SELECT person_id,employee_id
FROM silver.personnel
WHERE person_id != 0
  AND person_id != TRY_CAST(RIGHT(employee_id,5) AS INT);


-- 6. Employee ID format
SELECT person_id,employee_id
FROM silver.personnel
WHERE person_id != 0
  AND (
        LEN(employee_id) != 9
        OR SUBSTRING(employee_id,4,1) != '-'
        OR TRY_CAST(RIGHT(employee_id,5) AS INT) IS NULL
      );


-- 7. Employment type must match employee ID prefix
SELECT person_id,employee_id,employment_type
FROM silver.personnel
WHERE person_id != 0
  AND (
        (employment_type='Employee' AND LEFT(employee_id,3) != 'EMP')
        OR
        (employment_type='Contractor' AND LEFT(employee_id,3) != 'CTR')
      );


-- 8. Valid employment types
SELECT DISTINCT employment_type
FROM silver.personnel
WHERE employment_type NOT IN ('Employee','Contractor','Unknown');


-- 9. Contractor-company business logic
SELECT person_id,employment_type,contractor_company
FROM silver.personnel
WHERE person_id != 0
  AND (
        (employment_type='Employee'
            AND (contractor_company IS NULL OR contractor_company != 'None'))
        OR
        (employment_type='Contractor'
            AND (
                 contractor_company IS NULL
                 OR TRIM(contractor_company)=''
                 OR contractor_company='None'
                ))
      );


-- 10. Valid department categories
SELECT DISTINCT department
FROM silver.personnel
WHERE department NOT IN (
    'Engineering',
    'Drilling',
    'HSE',
    'Laboratory',
    'Logistics',
    'Maintenance',
    'Marine',
    'Operations',
    'Projects',
    'Security',
    'Unknown'
);


-- 11. Age-band code validation
-- age_band_code remains categorical VARCHAR rather than numeric
SELECT person_id,age_band_code
FROM silver.personnel
WHERE person_id != 0
  AND age_band_code NOT IN ('1','2','3','4','5');


-- 12. Years of experience cannot be negative
SELECT person_id,years_experience
FROM silver.personnel
WHERE years_experience<0;


-- 13. Unknown personnel member should not have a numeric experience value
SELECT person_id,employee_id,years_experience
FROM silver.personnel
WHERE person_id=0
  AND years_experience IS NOT NULL;


-- 14. Valid training statuses
SELECT DISTINCT training_status
FROM silver.personnel
WHERE training_status NOT IN (
    'Current',
    'Due within 30 days',
    'Expired',
    'Incomplete',
    'Unknown'
);


-- 15. Validate designated Unknown personnel member
SELECT *
FROM silver.personnel
WHERE person_id=0
  AND (
        employee_id != 'UNKNOWN'
        OR employment_type != 'Unknown'
        OR contractor_company != 'Unknown'
        OR department != 'Unknown'
        OR job_title != 'Unknown'
        OR age_band_code != 'Unknown'
        OR training_status != 'Unknown'
      );


-- 16. Confirm exactly one Unknown personnel member exists
SELECT COUNT(*) AS unknown_member_count
FROM silver.personnel
WHERE person_id=0;
-- Expected result: 1


/*
===============================================================================
Silver Data Quality Checks: silver.sites
===============================================================================

Purpose:
    Validate the Silver operating sites table after cleansing.

Checks:
    - Primary key and site code uniqueness
    - NULL and blank values
    - Leading and trailing spaces
    - Region and risk classification validity
    - Site code and country consistency
    - Review of categorical values

Business Rules:
    - site_id uniquely identifies each site.
    - site_code uniquely identifies each operating site.
    - Text fields must not contain unwanted spaces.
    - risk_classification must be High, Medium, or Low.
    - Region values must follow the agreed standardisation.
    - Site code country prefixes must correspond to the country.

Expected Result:
    Unless otherwise stated, exception queries should return 0 rows.
===============================================================================
*/


-- Primary key uniqueness and NULL check
SELECT
    site_id,
    COUNT(*) AS occurrence
FROM silver.sites
GROUP BY site_id
HAVING COUNT(*) > 1 OR site_id IS NULL;


-- Site code uniqueness and NULL/blank check
SELECT
    site_code,
    COUNT(*) AS occurrence
FROM silver.sites
GROUP BY site_code
HAVING COUNT(*) > 1 OR site_code IS NULL OR TRIM(site_code) = '';


-- NULL or blank descriptive fields
SELECT
    site_id,
    site_code,
    site_name,
    country,
    region,
    facility_type,
    operation_type,
    risk_classification
FROM silver.sites
WHERE site_name IS NULL OR TRIM(site_name) = ''
    OR country IS NULL OR TRIM(country) = ''
    OR region IS NULL OR TRIM(region) = ''
    OR facility_type IS NULL OR TRIM(facility_type) = ''
    OR operation_type IS NULL OR TRIM(operation_type) = ''
    OR risk_classification IS NULL OR TRIM(risk_classification) = '';


-- Leading and trailing spaces
SELECT
    site_id,
    site_code,
    site_name,
    country,
    region,
    facility_type,
    operation_type,
    risk_classification
FROM silver.sites
WHERE site_code != TRIM(site_code)
    OR site_name != TRIM(site_name)
    OR country != TRIM(country)
    OR region != TRIM(region)
    OR facility_type != TRIM(facility_type)
    OR operation_type != TRIM(operation_type)
    OR risk_classification != TRIM(risk_classification);


-- Region validity check
SELECT
    site_id,
    site_code,
    region
FROM silver.sites
WHERE region NOT IN ('Western Offshore','Western Region','Greater Accra','Niger Delta','Abidjan Offshore','Abidjan');


-- Risk classification validity check
SELECT
    site_id,
    site_code,
    risk_classification
FROM silver.sites
WHERE risk_classification NOT IN ('High','Medium','Low');


-- Site code and country logical consistency
SELECT
    site_id,
    site_code,
    country
FROM silver.sites
WHERE (country = 'Ghana' AND LEFT(site_code,2) != 'GH')
    OR (country = 'Nigeria' AND LEFT(site_code,2) != 'NG')
    OR (country = 'Côte d''Ivoire' AND LEFT(site_code,2) != 'CI');


-- Review site categorical values
SELECT DISTINCT
    country,
    region,
    facility_type,
    operation_type,
    risk_classification
FROM silver.sites
ORDER BY
    country,
    region;
-- Review only

/*
===============================================================================
Silver Data Quality Checks: silver.work_activities
===============================================================================

Purpose:
    Validate the Silver work activities table after cleansing.

Checks:
    - Primary key uniqueness and completeness
    - NULL, blank and unwanted-space values
    - Controlled categorical values
    - Review of activity categories

Business Rules:
    - activity_id uniquely identifies each work activity.
    - Text fields must not contain unwanted spaces.
    - permit_required and high_risk_activity must contain Yes or No.
    - work_type must be Routine or Non-Routine.
    - shift must be Day or Night.
    - risk_level must be High, Medium, or Low.
    - Activity categories must use the agreed standardized casing.

Expected Result:
    Unless otherwise stated, exception queries should return 0 rows.
===============================================================================
*/

-- Primary key uniqueness and NULL check
SELECT
    activity_id,
    COUNT(*) AS occurrence
FROM silver.work_activities
GROUP BY activity_id
HAVING COUNT(*) > 1 OR activity_id IS NULL;


-- NULL, blank, leading and trailing spaces
SELECT
    activity_id,
    activity_category,
    activity_name,
    work_type,
    shift,
    permit_required,
    high_risk_activity,
    risk_level
FROM silver.work_activities
WHERE activity_category IS NULL OR TRIM(activity_category) = ''
    OR activity_name IS NULL OR TRIM(activity_name) = ''
    OR work_type IS NULL OR TRIM(work_type) = ''
    OR shift IS NULL OR TRIM(shift) = ''
    OR permit_required IS NULL OR TRIM(permit_required) = ''
    OR high_risk_activity IS NULL OR TRIM(high_risk_activity) = ''
    OR risk_level IS NULL OR TRIM(risk_level) = ''
    OR activity_category != TRIM(activity_category)
    OR activity_name != TRIM(activity_name)
    OR work_type != TRIM(work_type)
    OR shift != TRIM(shift)
    OR permit_required != TRIM(permit_required)
    OR high_risk_activity != TRIM(high_risk_activity)
    OR risk_level != TRIM(risk_level);


-- Controlled categorical values
SELECT
    activity_id,
    work_type,
    shift,
    permit_required,
    high_risk_activity,
    risk_level
FROM silver.work_activities
WHERE work_type NOT IN ('Routine','Non-Routine')
    OR shift NOT IN ('Day','Night')
    OR permit_required NOT IN ('Yes','No')
    OR high_risk_activity NOT IN ('Yes','No')
    OR risk_level NOT IN ('High','Medium','Low');


-- Activity category validity check
SELECT
    activity_id,
    activity_category
FROM silver.work_activities
WHERE activity_category NOT IN ('Process Operations','Maintenance','Hot Work','Confined Space','Working at Height','Lifting','Drilling','Marine','Logistics','Warehouse','Chemical','Environmental','Pipeline','Tank Operations','Pressure Systems','Construction','Inspection','Laboratory','Emergency Response','Office','Security');


-- Review activity categories
SELECT DISTINCT
    activity_category
FROM silver.work_activities
ORDER BY activity_category;
-- Review only

