/*
===============================================================================
Gold Layer Views
===============================================================================

Purpose:
    Build the Gold layer of the HSE data warehouse using dimension and fact
    views designed for reporting and analytical use.

Process:
    - Creates dimension views for calendar, cause reference, equipment,
      personnel, sites and work activities.
    - Creates a fact view for HSE event records.
    - Generates surrogate keys for each dimension using ROW_NUMBER().
    - Retains the original Silver-layer business keys for traceability.
    - Links the fact view to the dimensions through the corresponding
      business keys.
    - Exposes cleaned Silver-layer data in a star-schema structure that is
      easier to use for reporting, dashboards and HSE analysis.

Important Notes:
    - All Gold-layer objects are implemented as views rather than physical
      tables.
    - Surrogate keys are generated dynamically using ROW_NUMBER() and are
      ordered by the corresponding Silver-layer business key.
    - The fact view has a grain of one row per HSE event record.
    - LEFT JOINs are used when linking event records to dimensions so that
      event records are retained even if a dimension match is unavailable.
    - Data cleansing and standardization are completed in the Silver layer;
      the Gold layer focuses on analytical organization and relationships.

===============================================================================
*/



-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_calendar
-- Grain: one row represents one calendar date
-- -------------------------------------------------------------------------------
IF OBJECT_ID ('gold.dim_calendar', 'V') IS NOT NULL
    DROP VIEW gold.dim_calendar;
GO

CREATE OR ALTER VIEW gold.dim_calendar AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY date_id) AS calendar_key, -- Generate a surrogate key for each calendar date
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
FROM silver.calendar;
GO

-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_cause_reference
-- Grain: one row represents one cause reference record
-- -------------------------------------------------------------------------------
IF OBJECT_ID ('gold.dim_cause_reference','V') IS NOT NULL
    DROP VIEW gold.dim_cause_reference;
GO

CREATE OR ALTER VIEW gold.dim_cause_reference AS
SELECT
    cause_id AS cause_reference_key,
    immediate_cause_category,
    immediate_cause,
    root_cause_category,
    root_cause,
    human_factor_flag,
    equipment_factor_flag,
    management_system_factor_flag
FROM silver.cause_reference;
GO

-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_equipment
-- Grain: one row represents one equipment record
-- -------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_equipment','V') IS NOT NULL
    DROP VIEW gold.dim_equipment;
GO

CREATE OR ALTER VIEW gold.dim_equipment AS
SELECT
    equipment_id AS equipment_key,
    asset_id,
    asset_type,
    criticality,
    install_year,
    asset_age_years,
    maintenance_status,
    inspection_status,
    home_site_id
FROM silver.equipment
GO

-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_personnel
-- Grain: one row represents one personnel record
-- -------------------------------------------------------------------------------
IF OBJECT_ID ('gold.dim_personnel','V') IS NOT NULL
    DROP VIEW gold.dim_personnel;
GO

CREATE OR ALTER VIEW gold.dim_personnel AS
SELECT
    person_id AS personnel_key,
    employee_id,
    employment_type,
    contractor_company,
    department,
    job_title,
    age_band_code AS age_group_code,
    years_experience,
    training_status
FROM silver.personnel;
GO

-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_sites
-- Grain: one row represents one site record
-- -------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_sites','V') IS NOT NULL
    DROP VIEW gold.dim_sites;
GO

CREATE OR ALTER VIEW gold.dim_sites AS
SELECT
    site_id AS site_key,
    site_code,
    site_name,
    country,
    region,
    facility_type,
    operation_type,
    risk_classification
FROM silver.sites;
GO

-- -------------------------------------------------------------------------------
-- Dimension View: gold.dim_work_activities
-- Grain: one row represents one activity record
-- -------------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_work_activities','V') IS NOT NULL
    DROP VIEW gold.dim_work_activities;
GO

CREATE OR ALTER VIEW gold.dim_work_activities AS
SELECT
    activity_id AS work_activity_key,
    activity_category,
    activity_name,
    work_type,
    shift,
    permit_required,
    high_risk_activity,
    risk_level
FROM silver.work_activities;
GO

-- -------------------------------------------------------------------------------
-- Fact View: gold.fact_event_records
-- Grain: one row represents one event record
-- -------------------------------------------------------------------------------
IF OBJECT_ID('gold.fact_event_records','V') IS NOT NULL
    DROP VIEW gold.fact_event_records;
GO

CREATE OR ALTER VIEW gold.fact_event_records AS
SELECT
    e.event_record_id AS event_record_key,
    e.event_id,
    c.calendar_key,
    s.site_key,
    p.personnel_key,
    eq.equipment_key,
    w.work_activity_key,
    cr.cause_reference_key,
    e.event_type,
    e.severity_class,
    e.process_safety_tier,
    e.recordable_flag,
    e.lost_time_flag,
    e.fatality_count,
    e.days_lost,
    e.restricted_days,
    e.spill_volume_l,
    e.incident_cost_usd,
    e.downtime_hours,
    e.regulator_reportable_flag
FROM silver.event_records e
LEFT JOIN gold.dim_calendar AS c ON e.event_date_id = c.date_id
LEFT JOIN gold.dim_cause_reference AS cr ON e.cause_id = cr.cause_reference_key
LEFT JOIN gold.dim_equipment AS eq ON e.equipment_id = eq.equipment_key
LEFT JOIN gold.dim_personnel AS p ON e.person_id = p.personnel_key
LEFT JOIN gold.dim_sites AS s ON e.site_id = s.site_key
LEFT JOIN gold.dim_work_activities AS w ON e.activity_id = w.work_activity_key;
GO