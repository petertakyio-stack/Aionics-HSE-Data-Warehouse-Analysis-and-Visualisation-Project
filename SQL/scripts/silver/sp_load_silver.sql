/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================

Purpose:
    Refresh and clean the Silver layer by transforming data from the Bronze
    tables into standardized, analysis-ready datasets.

Process:
    - Truncates and reloads all Silver tables as a full refresh.
    - Cleans and standardizes event records, calendar data, causes, equipment,
      personnel, operating sites and work activities.
    - Tracks the loading time for each table and the overall Silver-layer load.
    - Uses TRY/CATCH to capture and display any errors that occur during loading.

Main Cleaning Performed:
    - Event Records:
        Standardizes event dates and event types, removes records with invalid
        dates, cleans HSE measures, rebuilds event IDs and derives recordable
        and lost-time flags.

    - Calendar:
        Removes duplicate date records, rebuilds full dates from date_id and
        derives the required calendar attributes.

    - Cause Reference:
        Trims descriptive fields, standardizes text casing and preserves
        important abbreviations such as PPE and LOTO.

    - Equipment:
        Standardizes equipment classifications and maintenance status,
        removes placeholder numeric values and prepares valid site references.

    - Personnel:
        Standardizes employment type, department and training status,
        preserves the HSE abbreviation and removes placeholder experience
        values for the Unknown member.

    - Operating Sites:
        Trims site attributes and standardizes region and risk-classification
        values.

    - Work Activities:
        Standardizes activity categories, permit-required values and
        high-risk-activity values while trimming descriptive fields.

Important Notes:
    - The procedure performs a full refresh of the Silver layer using TRUNCATE
      followed by INSERT.
    - Invalid event dates are excluded rather than corrected or fabricated.
    - Placeholder values used for Unknown members are converted to NULL where
      the value represents unavailable information.
    - Source values that do not match known cleaning rules are generally
      retained after trimming rather than being automatically guessed.

Return:
    No result set is returned. Progress messages, table load durations,
    total load duration and SQL Server error details are displayed using PRINT.

Usage:
    EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;
    BEGIN TRY
        -- Record the start time of the complete silver-layer loading process.
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        -- =====================================================================
        -- 1. Load and clean the silver.event_records table
        -- =====================================================================

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.event_records';
        TRUNCATE TABLE silver.event_records;

        PRINT '>> Loading Table: silver.event_records';

        -- Standardize event dates and event-type descriptions.
        WITH cleaned AS (
            SELECT
                *,
                CAST(
                    CONVERT(VARCHAR(8),
                        COALESCE(
                            TRY_CONVERT(DATE,TRIM(event_date_id),112),
                            TRY_CONVERT(DATE,TRIM(event_date_id),23),
                            TRY_CONVERT(DATE,TRIM(event_date_id),111),
                            TRY_CONVERT(DATE,TRIM(event_date_id),103)),
                    112)
                AS INT) AS event_date_id1,
                CASE
                    WHEN LOWER(TRIM(event_type)) IN ('fac','first aid case') THEN 'First Aid Case'
                    WHEN LOWER(TRIM(event_type)) IN ('lti','lost time injury','lost  time injury','lost-time injury') THEN 'Lost Time Injury'
                    WHEN LOWER(TRIM(event_type)) IN ('medical treatment case','mtc') THEN 'Medical Treatment Case'
                    WHEN LOWER(TRIM(event_type)) IN ('nearmiss','near-miss','near miss') THEN 'Near Miss'
                    WHEN LOWER(TRIM(event_type)) IN ('spill / release','spill release','spill/release') THEN 'Spill / Release'
                    WHEN LOWER(TRIM(event_type)) IN ('vehicle accident','vehicle incident') THEN 'Vehicle Incident / Accident'
                    WHEN LOWER(TRIM(event_type)) = 'fatality' THEN 'Fatality'
                    WHEN LOWER(TRIM(event_type)) = 'property damage' THEN 'Property Damage'
                    ELSE TRIM(event_type)
                END AS event_type1
            FROM bronze.event_records
        ),

        -- Clean HSE measures and exclude records with invalid event dates.
        metrics_cleaned AS (
            SELECT
                *,
                CASE
                    WHEN event_type1 IN ('First Aid Case','Near Miss','Property Damage') THEN 0
                    WHEN event_type1 = 'Fatality'
                        AND (TRY_CAST(fatality_count AS INT) <= 0 OR TRY_CAST(fatality_count AS INT) IS NULL) THEN 1
                    ELSE TRY_CAST(fatality_count AS INT)
                END AS fatality_count1,
                CASE
                    WHEN days_lost < 0 THEN NULL
                    WHEN event_type1 IN ('Near Miss','First Aid Case') AND days_lost > 0 THEN 0
                    WHEN event_type1 = 'Lost Time Injury' AND days_lost <= 0 THEN NULL
                    WHEN days_lost > 180 THEN 180
                    ELSE days_lost
                END AS days_lost1,
                TRY_CAST(REPLACE(LOWER(TRIM(restricted_days)),' days','') AS INT) AS restricted_days1
            FROM cleaned
            WHERE event_date_id1 IS NOT NULL
        )

        INSERT INTO silver.event_records(
            event_record_id,
            event_id,
            event_date_id,
            site_id,
            person_id,
            equipment_id,
            activity_id,
            cause_id,
            event_type,
            severity_class,
            process_safety_tier,
            recordable_flag,
            lost_time_flag,
            fatality_count,
            days_lost,
            restricted_days,
            spill_volume_l,
            incident_cost_usd,
            downtime_hours,
            regulator_reportable_flag
        )

        -- Rebuild event IDs, derive HSE flags and load the cleaned records into Silver.
        SELECT
            event_record_id,
            CONCAT('HSE-',LEFT(CAST(event_date_id1 AS VARCHAR(8)),4),'-',RIGHT('000000' + CAST(event_record_id AS VARCHAR(6)),6)) AS event_id,
            event_date_id1 AS event_date_id,
            site_id,
            person_id,
            equipment_id,
            activity_id,
            cause_id,
            event_type1 AS event_type,
            TRIM(severity_class) AS severity_class,
            TRIM(process_safety_tier) AS process_safety_tier,
            CASE
                WHEN event_type1 IN ('Fatality','Lost Time Injury','Medical Treatment Case') THEN 1
                WHEN fatality_count1 > 0 THEN 1
                WHEN restricted_days1 > 0 THEN 1
                ELSE 0
            END AS recordable_flag,
            CASE
                WHEN event_type1 = 'Lost Time Injury' THEN 1
                ELSE 0
            END AS lost_time_flag,
            fatality_count1 AS fatality_count,
            days_lost1 AS days_lost,
            restricted_days1 AS restricted_days,
            spill_volume_l,
            incident_cost_usd,
            downtime_hours,
            regulator_reportable_flag
        FROM metrics_cleaned;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- ===================================================================
        -- 2. Load and clean the silver.calendar table
        -- ===================================================================

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.calendar';
        TRUNCATE TABLE silver.calendar;

        PRINT '>> Loading Table: silver.calendar';

        -- Rebuild valid dates from date_id and remove duplicate date records.
        SET DATEFIRST 1;

        WITH cleaned AS (
            SELECT
                date_id,
                CAST(CAST(date_id AS NVARCHAR) AS DATE) AS full_date,
                ROW_NUMBER() OVER (PARTITION BY date_id ORDER BY full_date DESC) AS flag
            FROM bronze.calendar
        )

        INSERT INTO silver.calendar (
            date_id,
            full_date,
            day_name,
            day_of_week,
            week_of_year,
            month_number,
            month_name,
            quarter,
            year,
            is_weekend
        )

        -- Derive calendar attributes from the cleaned full_date.
        SELECT
            date_id,
            full_date,
            DATENAME(weekday,full_date) AS day_name,
            DATEPART(weekday,full_date) AS day_of_week,
            DATEPART(iso_week,full_date) AS week_of_year,
            DATEPART(month,full_date) AS month_number,
            DATENAME(month,full_date) AS month_name,
            DATEPART(quarter,full_date) AS quarter,
            DATEPART(year,full_date) AS year,
            CASE
                WHEN DATEPART(weekday,full_date) > 5 THEN 1
                ELSE 0
            END AS is_weekend
        FROM cleaned
        WHERE flag = 1;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- ==============================================================
        -- 3. Load and clean the silver.cause_reference table
        -- ==============================================================*/

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.cause_reference';
        TRUNCATE TABLE silver.cause_reference;

        PRINT '>> Loading Table: silver.cause_reference';

        -- Trim descriptive fields, standardize casing and preserve key abbreviations.
        INSERT INTO silver.cause_reference (
            cause_id,
            immediate_cause_category,
            immediate_cause,
            root_cause_category,
            root_cause,
            human_factor_flag,
            equipment_factor_flag,
            management_system_factor_flag
        )

        SELECT
            cause_id,
            REPLACE(REPLACE(
                UPPER(LEFT(TRIM(immediate_cause_category),1)) + LOWER(SUBSTRING(TRIM(immediate_cause_category),2,LEN(TRIM(immediate_cause_category)))),
                'Ppe','PPE'),'Loto','LOTO') AS immediate_cause_category,
            REPLACE(REPLACE(
                UPPER(LEFT(TRIM(immediate_cause),1)) + LOWER(SUBSTRING(TRIM(immediate_cause),2,LEN(TRIM(immediate_cause)))),
                'Ppe','PPE'),'Loto','LOTO') AS immediate_cause,
            REPLACE(REPLACE(
                UPPER(LEFT(TRIM(root_cause_category),1)) + LOWER(SUBSTRING(TRIM(root_cause_category),2,LEN(TRIM(root_cause_category)))),
                'Ppe','PPE'),'Loto','LOTO') AS root_cause_category,
            REPLACE(REPLACE(
                UPPER(LEFT(TRIM(root_cause),1)) + LOWER(SUBSTRING(TRIM(root_cause),2,LEN(TRIM(root_cause)))),
                'Ppe','PPE'),'Loto','LOTO') AS root_cause,
            human_factor_flag,
            equipment_factor_flag,
            management_system_factor_flag
        FROM bronze.cause_reference;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- ==============================================================
        -- 4. Load and clean the silver.equipment table
        -- ==============================================================*/

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.equipment';
        TRUNCATE TABLE silver.equipment;

        PRINT '>> Loading Table: silver.equipment';

        -- Standardize equipment classifications and convert unavailable numeric values to NULL.
        INSERT INTO silver.equipment (
            equipment_id,
            asset_id,
            asset_type,
            criticality,
            install_year,
            asset_age_years,
            maintenance_status,
            inspection_status,
            home_site_id
        )

        SELECT
            equipment_id,
            TRIM(asset_id) AS asset_id,
            TRIM(asset_type) AS asset_type,

            -- Standardize criticality classifications.
            CASE
                WHEN LOWER(TRIM(criticality)) = 'a - critical' THEN 'A - Critical'
                WHEN LOWER(TRIM(criticality)) = 'b - important' THEN 'B - Important'
                WHEN LOWER(TRIM(criticality)) = 'c - general' THEN 'C - General'
                ELSE TRIM(criticality)
            END AS criticality,

            -- Treat install_year = 0 as unavailable rather than a valid year.
            NULLIF(install_year,0) AS install_year,

            -- Preserve valid zero age for new equipment, but remove the Unknown member's placeholder age.
            CASE
                WHEN install_year = 0 AND asset_age_years = 0 THEN NULL
                ELSE asset_age_years
            END AS asset_age_years,

            -- Standardize maintenance-status values.
            CASE
                WHEN LOWER(TRIM(maintenance_status)) = 'good' THEN 'Good'
                WHEN LOWER(TRIM(maintenance_status)) = 'overdue' THEN 'Overdue'
                WHEN LOWER(TRIM(maintenance_status)) = 'maintenance due' THEN 'Maintenance Due'
                WHEN LOWER(TRIM(maintenance_status)) = 'monitor' THEN 'Monitor'
                ELSE TRIM(maintenance_status)
            END AS maintenance_status,

            TRIM(inspection_status) AS inspection_status,

            -- Convert home_site_id to INT and treat 0 as an unavailable site reference.
            NULLIF(TRY_CAST(home_site_id AS INT),0) AS home_site_id
        FROM bronze.equipment;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';


        -- ==============================================================
        -- 5. Load and clean the silver.personnel table
        -- ==============================================================*/

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.personnel';
        TRUNCATE TABLE silver.personnel;

        PRINT '>> Loading Table: silver.personnel';

        -- Standardize personnel categories, preserve key abbreviations and clean Unknown-member values.
        INSERT INTO silver.personnel (
            person_id,
            employee_id,
            employment_type,
            contractor_company,
            department,
            job_title,
            age_band_code,
            years_experience,
            training_status
        )

        SELECT
            person_id,
            TRIM(employee_id) AS employee_id,

            -- Standardize employment-type values.
            CASE
                WHEN LOWER(TRIM(employment_type)) = 'employee' THEN 'Employee'
                WHEN LOWER(TRIM(employment_type)) = 'contractor' THEN 'Contractor'
                ELSE TRIM(employment_type)
            END AS employment_type,

            TRIM(contractor_company) AS contractor_company,

            -- Standardize department casing while preserving the HSE abbreviation.
            CASE
                WHEN UPPER(TRIM(department)) = 'HSE' THEN 'HSE'
                ELSE UPPER(LEFT(TRIM(department),1)) + LOWER(SUBSTRING(TRIM(department),2,LEN(TRIM(department))))
            END AS department,

            TRIM(job_title) AS job_title,
            TRIM(age_band_code) AS age_band_code,

            -- Remove the placeholder experience value assigned to the Unknown personnel member.
            CASE
                WHEN person_id = 0 AND years_experience = 0 THEN NULL
                ELSE years_experience
            END AS years_experience,

            -- Standardize training-status values.
            CASE
                WHEN LOWER(TRIM(training_status)) = 'current' THEN 'Current'
                WHEN LOWER(TRIM(training_status)) = 'due within 30 days' THEN 'Due within 30 days'
                WHEN LOWER(TRIM(training_status)) = 'expired' THEN 'Expired'
                WHEN LOWER(TRIM(training_status)) = 'incomplete' THEN 'Incomplete'
                ELSE TRIM(training_status)
            END AS training_status
        FROM bronze.personnel;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- ==============================================================
        -- 6. Load and clean the silver.sites table
        -- ==============================================================*/

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.sites';
        TRUNCATE TABLE silver.sites;

        PRINT '>> Loading Table: silver.sites';

        -- Trim site attributes and standardize region and risk-classification values.
        INSERT INTO silver.sites (
            site_id,
            site_code,
            site_name,
            country,
            region,
            facility_type,
            operation_type,
            risk_classification
        )

        SELECT
            site_id,
            TRIM(site_code) AS site_code,
            TRIM(site_name) AS site_name,
            TRIM(country) AS country,

            -- Standardize known region casing variations.
            CASE
                WHEN LOWER(TRIM(region)) = 'abidjan' THEN 'Abidjan'
                WHEN LOWER(TRIM(region)) = 'western region' THEN 'Western Region'
                ELSE TRIM(region)
            END AS region,

            TRIM(facility_type) AS facility_type,
            TRIM(operation_type) AS operation_type,

            -- Standardize site risk-classification values.
            CASE
                WHEN LOWER(TRIM(risk_classification)) = 'high' THEN 'High'
                WHEN LOWER(TRIM(risk_classification)) = 'medium' THEN 'Medium'
                WHEN LOWER(TRIM(risk_classification)) = 'low' THEN 'Low'
                ELSE TRIM(risk_classification)
            END AS risk_classification
        FROM bronze.sites;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- ==============================================================
        -- 7. Load and clean the silver.work_activities table
        -- ==============================================================*/

        -- Track table load duration.
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.work_activities';
        TRUNCATE TABLE silver.work_activities;

        PRINT '>> Loading Table: silver.work_activities';

        -- Trim activity attributes and standardize categorical and Yes/No values.
        INSERT INTO silver.work_activities (
            activity_id,
            activity_category,
            activity_name,
            work_type,
            shift,
            permit_required,
            high_risk_activity,
            risk_level
        )

        SELECT
            activity_id,

            -- Standardize known activity-category casing variations.
            CASE
                WHEN LOWER(TRIM(activity_category)) = 'chemical' THEN 'Chemical'
                WHEN LOWER(TRIM(activity_category)) = 'logistics' THEN 'Logistics'
                WHEN LOWER(TRIM(activity_category)) = 'maintenance' THEN 'Maintenance'
                WHEN LOWER(TRIM(activity_category)) = 'pressure systems' THEN 'Pressure Systems'
                ELSE TRIM(activity_category)
            END AS activity_category,

            TRIM(activity_name) AS activity_name,
            TRIM(work_type) AS work_type,
            TRIM(shift) AS shift,

            -- Standardize permit-required values.
            CASE
                WHEN LOWER(TRIM(permit_required)) = 'no' THEN 'No'
                WHEN LOWER(TRIM(permit_required)) = 'yes' THEN 'Yes'
                ELSE TRIM(permit_required)
            END AS permit_required,

            -- Standardize high-risk-activity values independently of permit requirements.
            CASE
                WHEN LOWER(TRIM(high_risk_activity)) = 'no' THEN 'No'
                WHEN LOWER(TRIM(high_risk_activity)) = 'yes' THEN 'Yes'
                ELSE TRIM(high_risk_activity)
            END AS high_risk_activity,

            TRIM(risk_level) AS risk_level
        FROM bronze.work_activities;

        -- Display table load duration.
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> ----------------------------------------------------------------------';

        -- Record the completion time of the complete silver-layer load.
        SET @batch_end_time = GETDATE();

        -- Display the successful completion message and total load duration.
        PRINT '================================================';
        PRINT 'Silver Layer Loading Completed Successfully';
        PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER-LAYER LOADING';

        -- Display the SQL Server error description.
        PRINT 'Error Message: ' + ERROR_MESSAGE();

        -- Display the SQL Server error number.
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);

        -- Display the SQL Server error state.
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;

-- EXEC silver.load_silver