/*
===============================================================================
Silver Layer DDL
===============================================================================

Purpose:
    Create the tables used to store cleaned and standardized data in the
    Silver layer of the HSE data warehouse.

Process:
    - Drops each Silver table if it already exists and recreates it with the
      required data types.
    - Uses appropriate numeric and date data types after Bronze-layer values
      have been cleaned and converted.
    - Adds dwh_create_date to every table to record when each row is loaded
      into the Silver layer.

Tables Created:
    - silver.event_records
    - silver.calendar
    - silver.cause_reference
    - silver.equipment
    - silver.personnel
    - silver.sites
    - silver.work_activities

Important Notes:
    - Silver tables contain cleaned and standardized data from the Bronze layer.
    - IDs used for relationships between tables are stored as INT.
    - HSE measures such as spill volume, incident cost and downtime are stored
      as DECIMAL to preserve numeric precision.
    - Placeholder or unavailable values cleaned during the Silver load may be
      stored as NULL.
    - dwh_create_date is automatically populated when a record is inserted.

===============================================================================
*/


/*==============================================================
  1. EVENT RECORDS
==============================================================*/

IF OBJECT_ID('silver.event_records','U') IS NOT NULL
    DROP TABLE silver.event_records;
GO

-- Stores cleaned HSE event records and their operational measures.
CREATE TABLE silver.event_records (
    event_record_id INT,
    event_id NVARCHAR(50),
    event_date_id INT,
    site_id INT,
    person_id INT,
    equipment_id INT,
    activity_id INT,
    cause_id INT,
    event_type VARCHAR(100),
    severity_class VARCHAR(50),
    process_safety_tier VARCHAR(50),
    recordable_flag INT,
    lost_time_flag INT,
    fatality_count INT,
    days_lost INT,
    restricted_days INT,
    spill_volume_l DECIMAL(15,2),
    incident_cost_usd DECIMAL(15,2),
    downtime_hours DECIMAL(15,2),
    regulator_reportable_flag INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  2. CALENDAR
==============================================================*/

IF OBJECT_ID('silver.calendar','U') IS NOT NULL
    DROP TABLE silver.calendar;
GO

-- Stores one cleaned calendar record per date with derived date attributes.
CREATE TABLE silver.calendar (
    date_id INT,
    full_date DATE,
    day_name VARCHAR(50),
    day_of_week INT,
    week_of_year INT,
    month_number INT,
    month_name VARCHAR(50),
    quarter INT,
    year INT,
    is_weekend INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  3. HSE CAUSE REFERENCE
==============================================================*/

IF OBJECT_ID('silver.cause_reference','U') IS NOT NULL
    DROP TABLE silver.cause_reference;
GO

-- Stores standardized immediate and root causes with HSE factor classifications.
CREATE TABLE silver.cause_reference (
    cause_id INT,
    immediate_cause_category VARCHAR(80),
    immediate_cause VARCHAR(100),
    root_cause_category VARCHAR(100),
    root_cause VARCHAR(80),
    human_factor_flag INT,
    equipment_factor_flag INT,
    management_system_factor_flag INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  4. EQUIPMENT
==============================================================*/

IF OBJECT_ID('silver.equipment','U') IS NOT NULL
    DROP TABLE silver.equipment;
GO

-- Stores cleaned equipment information and the associated operating site.
CREATE TABLE silver.equipment (
    equipment_id INT,
    asset_id NVARCHAR(80),
    asset_type VARCHAR(80),
    criticality VARCHAR(80),
    install_year INT,
    asset_age_years INT,
    maintenance_status VARCHAR(80),
    inspection_status VARCHAR(80),
    home_site_id INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  5. PERSONNEL
==============================================================*/

IF OBJECT_ID('silver.personnel','U') IS NOT NULL
    DROP TABLE silver.personnel;
GO

-- Stores standardized employee and contractor information used in HSE analysis.
CREATE TABLE silver.personnel (
    person_id INT,
    employee_id NVARCHAR(80),
    employment_type VARCHAR(80),
    contractor_company VARCHAR(100),
    department VARCHAR(80),
    job_title VARCHAR(80),
    age_band_code VARCHAR(80),
    years_experience FLOAT(2),
    training_status VARCHAR(80),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  6. OPERATING SITES
==============================================================*/

IF OBJECT_ID('silver.sites','U') IS NOT NULL
    DROP TABLE silver.sites;
GO

-- Stores standardized operating-site and facility information.
CREATE TABLE silver.sites (
    site_id INT,
    site_code NVARCHAR(80),
    site_name VARCHAR(100),
    country VARCHAR(80),
    region VARCHAR(80),
    facility_type VARCHAR(80),
    operation_type VARCHAR(80),
    risk_classification VARCHAR(80),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================
  7. WORK ACTIVITIES
==============================================================*/

IF OBJECT_ID('silver.work_activities','U') IS NOT NULL
    DROP TABLE silver.work_activities;
GO

-- Stores standardized work activities and their associated HSE risk attributes.
CREATE TABLE silver.work_activities (
    activity_id INT,
    activity_category VARCHAR(80),
    activity_name VARCHAR(80),
    work_type VARCHAR(80),
    shift VARCHAR(80),
    permit_required VARCHAR(80),
    high_risk_activity VARCHAR(80),
    risk_level VARCHAR(80),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO