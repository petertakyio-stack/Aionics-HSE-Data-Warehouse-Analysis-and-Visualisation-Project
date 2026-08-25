/*==============================================================
  HSE DATA WAREHOUSE PROJECT
  BRONZE LAYER - SOURCE TABLE CREATION

  Purpose:
  Create the Bronze-layer tables used to receive the HSE source
  CSV files. Existing tables are dropped to support a full reload.
==============================================================*/


/*==============================================================
  1. HSE EVENT RECORDS
==============================================================*/

-- Drop the existing table before performing a full reload.
IF OBJECT_ID ('bronze.event_records', 'U') IS NOT NULL
    DROP TABLE bronze.event_records;
GO

CREATE TABLE bronze.event_records (
    event_record_id INT,
    event_id VARCHAR(50),
    event_date_id VARCHAR(50),
    site_id INT,
    person_id INT,
    equipment_id INT,
    activity_id INT,
    cause_id INT,
    event_type VARCHAR(100),
    severity_class VARCHAR(50),
    process_safety_tier VARCHAR(50),
    recordable_flag VARCHAR(20),
    lost_time_flag VARCHAR(20),
    fatality_count VARCHAR(50),
    days_lost INT,
    restricted_days VARCHAR(50),
    spill_volume_l VARCHAR(50),
    incident_cost_usd VARCHAR(50),
    downtime_hours VARCHAR(50),
    regulator_reportable_flag VARCHAR(20)
);
GO


/*==============================================================
  2. CALENDAR
==============================================================*/

IF OBJECT_ID ('bronze.calendar', 'U') IS NOT NULL
    DROP TABLE bronze.calendar;
GO

CREATE TABLE bronze.calendar (
    date_id INT,
    full_date DATE,
    day_name VARCHAR(50),
    day_of_week INT,
    week_of_year INT,
    month_number INT,
    month_name VARCHAR(50),
    quarter INT,
    year INT,
    is_weekend INT
);
GO


/*==============================================================
  3. HSE CAUSE REFERENCE
==============================================================*/

IF OBJECT_ID ('bronze.cause_reference', 'U') IS NOT NULL
    DROP TABLE bronze.cause_reference;
GO

CREATE TABLE bronze.cause_reference (
    cause_id INT,
    immediate_cause_category VARCHAR(80),
    immediate_cause VARCHAR(100),
    root_cause_category VARCHAR(100),
    root_cause VARCHAR(80),
    human_factor_flag INT,
    equipment_factor_flag INT,
    management_system_factor_flag INT
);
GO


/*==============================================================
  4. EQUIPMENT
==============================================================*/

IF OBJECT_ID ('bronze.equipment', 'U') IS NOT NULL
    DROP TABLE bronze.equipment;
GO

CREATE TABLE bronze.equipment (
    equipment_id INT,
    asset_id NVARCHAR(80),
    asset_type VARCHAR(80),
    criticality VARCHAR(80),
    install_year INT,
    asset_age_years INT,
    maintenance_status VARCHAR(80),
    inspection_status VARCHAR(80),
    home_site_id VARCHAR(80)
);
GO


/*==============================================================
  5. PERSONNEL
==============================================================*/

IF OBJECT_ID ('bronze.personnel', 'U') IS NOT NULL
    DROP TABLE bronze.personnel;
GO

CREATE TABLE bronze.personnel (
    person_id INT,
    employee_id NVARCHAR(80),
    employment_type VARCHAR(80),
    contractor_company VARCHAR(100),
    department VARCHAR(80),
    job_title VARCHAR(80),
    age_band_code VARCHAR(80),
    years_experience FLOAT (2),
    training_status VARCHAR(80)
);
GO


/*==============================================================
  6. OPERATING SITES
==============================================================*/

IF OBJECT_ID ('bronze.sites', 'U') IS NOT NULL
    DROP TABLE bronze.sites;
GO

CREATE TABLE bronze.sites (
    site_id INT,
    site_code NVARCHAR(80),
    site_name VARCHAR(100),
    country VARCHAR(80),
    region VARCHAR(80),
    facility_type VARCHAR(80),
    operation_type VARCHAR(80),
    risk_classification VARCHAR(80)
);
GO


/*==============================================================
  7. WORK ACTIVITIES
==============================================================*/

IF OBJECT_ID ('bronze.work_activities', 'U') IS NOT NULL
    DROP TABLE bronze.work_activities;
GO

CREATE TABLE bronze.work_activities (
    activity_id INT,
    activity_category VARCHAR(80),
    activity_name VARCHAR(80),
    work_type VARCHAR(80),
    shift VARCHAR(80),
    permit_required VARCHAR(80),
    high_risk_activity VARCHAR(80),
    risk_level VARCHAR(80)
);
GO
