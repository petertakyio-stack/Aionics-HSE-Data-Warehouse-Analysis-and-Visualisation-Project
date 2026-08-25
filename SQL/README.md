# Aionics Solutions HSE Data Warehouse Project

## Project Overview

This project transforms a fictional Health, Safety, and Environment (HSE) operational dataset from **Aionics Solutions, Ghana** into a structured, analytics-ready data warehouse using SQL Server and a layered data architecture.

The project demonstrates an end-to-end data engineering workflow, including:
- Extracting HSE data from CSV source files
- Loading raw source data into a Bronze layer
- Cleaning and standardising data in a Silver layer
- Building dimension and fact views in a Gold layer
- Designing a star schema for HSE reporting and analytics
- Implementing stored procedures for repeatable ETL processing
- Performing data-quality checks across Silver and Gold layers
- Preparing business-ready HSE measures for incident, safety, environmental, cost, and downtime analysis

The project was developed as part of my data engineering portfolio to demonstrate practical skills in **SQL, ETL development, data warehousing, dimensional modelling, data transformation, data validation, and technical documentation**.

> **Note:** The Aionics Solutions HSE dataset used in this project is fictional and was created for learning and portfolio purposes.

---

## High Level Architecture

The warehouse follows a three-layer **Medallion Architecture**.

<p align="center">
  <img width="1200" alt="Aionics HSE Data Architecture" src="docs/images/aionics_data_architecture.png" />
  <br>
  <em>Figure 1: End-to-end HSE data architecture from source files through the Bronze, Silver, and Gold layers to BI and analytics consumers.</em>
</p>

<p align="center">
  <img width="1100" alt="Aionics HSE Data Flow" src="docs/images/aionics_data_flow.png" />
  <br>
  <em>Figure 2: HSE data flow showing the source-aligned Bronze layer, cleansed Silver layer, and analytical Gold layer.</em>
</p>

<p align="center">
  <img width="1100" alt="Aionics HSE Data Integration Model" src="docs/images/aionics_data_integration.png" />
  <br>
  <em>Figure 3: Source data integration model showing how event records connect to calendar, personnel, equipment, sites, causes, and work activities.</em>
</p>

### Bronze Layer

Stores raw or near-raw HSE source data. The Bronze layer creates source-aligned tables, reloads CSV files using `BULK INSERT`, preserves original values, tracks load duration, and captures load errors.

The Bronze layer contains:
- `bronze.event_records`
- `bronze.calendar`
- `bronze.cause_reference`
- `bronze.equipment`
- `bronze.personnel`
- `bronze.sites`
- `bronze.work_activities`

### Silver Layer

Cleans and standardises Bronze data before analytical use.

Major transformations include:
- Standardising multiple event-date formats
- Excluding event records with invalid dates
- Rebuilding consistent HSE event IDs
- Standardising event-type descriptions
- Cleaning fatality, lost-day, and restricted-day measures
- Recreating recordable and lost-time flags
- Removing duplicate calendar records
- Rebuilding calendar attributes from trusted dates
- Trimming text values and correcting inconsistent casing
- Preserving recognised HSE abbreviations such as `HSE`, `PPE`, and `LOTO`
- Standardising equipment criticality and maintenance status
- Standardising personnel employment and training categories
- Handling selected placeholder values as `NULL`
- Standardising site region and risk-classification values
- Standardising work-activity, permit-required, and high-risk-activity values

The Silver layer is refreshed through the stored procedure:

```sql
EXEC silver.load_silver;
```

### Gold Layer

Presents business-ready HSE dimension and fact views in a star-schema structure for reporting, dashboarding, and analytical use.

All Gold-layer objects are implemented as **SQL views** rather than physical tables.

---

## Gold Layer - HSE Data Model

<p align="center">
  <img width="1100" alt="Aionics HSE Gold Star Schema" src="docs/images/aionics_data_model.png" />
  <br>
  <em>Figure 4: Gold-layer dimensional model linking the HSE event fact view to calendar, personnel, equipment, sites, work-activity, and cause-reference dimensions.</em>
</p>

**Fact-view grain:** One row represents one HSE event record.

### Dimension Views
- `gold.dim_calendar`
- `gold.dim_cause_reference`
- `gold.dim_equipment`
- `gold.dim_personnel`
- `gold.dim_sites`
- `gold.dim_work_activities`

### Fact View
- `gold.fact_event_records`

### Key Features
- CSV loading with `BULK INSERT`
- Bronze and Silver ETL stored procedures
- Data cleansing and standardisation
- CTE-based transformations
- Multi-format date handling using `TRY_CONVERT`
- HSE business-rule transformations using `CASE`
- Star-schema dimensional modelling
- Gold-layer analytical views
- Dynamically generated calendar key
- Stable dimension keys retained from cleaned Silver identifiers where appropriate
- Silver and Gold data-quality checks
- ETL duration tracking
- Error handling with `TRY...CATCH`

---

## HSE Fact Measures

| Measure / Indicator | Description |
|---|---|
| **Recordable Flag** | Identifies whether an HSE event is recordable |
| **Lost Time Flag** | Identifies a Lost Time Injury event |
| **Fatality Count** | Number of fatalities associated with an event |
| **Days Lost** | Number of workdays lost as a result of an event |
| **Restricted Days** | Number of restricted-work days associated with an event |
| **Spill Volume (L)** | Volume of an environmental spill or release in litres |
| **Incident Cost (USD)** | Estimated financial cost associated with the incident |
| **Downtime Hours** | Operational downtime caused by the event |
| **Regulator Reportable Flag** | Identifies events that require regulatory reporting |

---

## Data Quality Checks

The project validates data at both Silver and Gold layers.

### Silver Layer Checks
- Duplicate and NULL primary keys
- Invalid or inconsistent dates
- Event-ID format and consistency
- Missing dimension references
- Invalid categorical values
- Incorrect binary flag values
- Recordable-event logic
- Lost-time logic
- Fatality-count logic
- Invalid lost-day or restricted-day values
- Negative spill, cost, or downtime values
- Equipment and personnel Unknown-member consistency
- Equipment-to-site relationships
- Personnel employment and contractor-company rules
- Site-code and country consistency
- Work-activity category and Yes/No standardisation

### Gold Layer Checks
- Duplicate dimension keys
- Duplicate calendar business keys
- Duplicate event keys or event IDs
- Silver-to-Gold row-count reconciliation
- Missing dimension keys in the fact view
- Fact-to-dimension referential integrity

---

## Run Order

1. Database and schema setup
2. Bronze table creation
3. Bronze data load
4. Bronze data validation
5. Silver table creation
6. Silver data load
7. Silver quality checks
8. Gold view creation
9. Gold quality checks
10. Connect Gold views to BI or reporting tools

---

## Skills Demonstrated
## Skills & Technologies

<p align="left">
  <img src="https://img.shields.io/badge/SQL%20Server-Database%20Development-CC2927?logo=microsoftsqlserver&logoColor=white" />
  <img src="https://img.shields.io/badge/ETL-Data%20Pipelines-0A66C2" />
  <img src="https://img.shields.io/badge/Data%20Warehousing-Analytics%20Ready-6F42C1" />
  <img src="https://img.shields.io/badge/Medallion%20Architecture-Bronze%20%7C%20Silver%20%7C%20Gold-D4A017" />
  <img src="https://img.shields.io/badge/Star%20Schema-Dimensional%20Modelling-2E8B57" />
  <img src="https://img.shields.io/badge/Window%20Functions-Advanced%20SQL-00758F" />
  <img src="https://img.shields.io/badge/CTEs-Readable%20Transformations-4B8BBE" />
  <img src="https://img.shields.io/badge/Data%20Quality-Validation%20%26%20Testing-28A745" />
  <img src="https://img.shields.io/badge/HSE-Analytics-5B6B73" />
</p>

---

## BI: Analytics & Reporting

The Gold layer provides an analytics-ready HSE star schema that can be connected to tools such as **Power BI, Tableau, or Excel** to build interactive HSE dashboards and management reports.

### Key Performance Indicators

| KPI | Description |
|---|---|
| **Total HSE Events** | Total number of HSE event records |
| **Recordable Events** | Number of events classified as recordable |
| **Recordable Event Percentage** | Percentage of HSE events that are recordable |
| **Lost Time Injuries** | Number of Lost Time Injury events |
| **Total Fatalities** | Total number of fatalities recorded |
| **Total Days Lost** | Total workdays lost due to HSE events |
| **Total Restricted Days** | Total restricted-work days |
| **Total Spill Volume** | Total litres of recorded environmental spills or releases |
| **Total Incident Cost** | Total estimated financial impact of HSE incidents |
| **Total Downtime Hours** | Total operational downtime caused by incidents |
| **Regulator Reportable Events** | Number of events requiring regulatory reporting |
| **High-Severity Events** | Number of events falling within higher severity classifications |

### Critical Business Questions
- Which operating sites record the highest number of HSE events?
- Which sites have the highest recordable-event counts?
- Which work activities are most frequently associated with incidents?
- Which high-risk activities contribute most to serious events?
- Which event types generate the greatest number of lost workdays?
- Which departments or employment groups are most frequently associated with HSE events?
- Which equipment types or criticality classes are linked to the highest incident frequency?
- Do overdue maintenance or inspection conditions appear frequently in event records?
- What are the most common immediate and root causes of HSE events?
- Are human, equipment, or management-system factors the dominant contributors?
- Which sites or activities generate the highest incident costs?
- Where is operational downtime greatest?
- Which event types account for the largest spill volumes?
- How do HSE event volumes and severity change over time?
- Which months, quarters, or years show the strongest or weakest HSE performance?
- Which events are most frequently classified as regulator reportable?
- How do day and night shifts compare in terms of incident occurrence and severity?

---

## Data Catalog

A Gold-layer data catalog is maintained to document:
- View names and purposes
- Grain of each dimension and fact view
- Column definitions
- Data types
- Key classifications
- HSE measures and analytical attributes

---

## Project Structure

```text
Aionics-HSE-Data-Warehouse/
│
├── datasets/
│   ├── calendar.csv
│   ├── cause_reference.csv
│   ├── equipment.csv
│   ├── event_records.csv
│   ├── personnel.csv
│   ├── sites.csv
│   └── work_activities.csv
│
├── scripts/
│   ├── 01_database_setup.sql
│   ├── 02_bronze_ddl.sql
│   ├── 03_bronze_load.sql
│   ├── 04_silver_ddl.sql
│   ├── 05_silver_load.sql
│   ├── 06_silver_quality_checks.sql
│   ├── 07_gold_views.sql
│   └── 08_gold_quality_checks.sql
│
├── docs/
│   ├── HSE_Gold_Layer_Data_Catalog.docx
│   └── images/
│       ├── aionics_data_architecture.png
│       ├── aionics_data_flow.png
│       ├── aionics_data_integration.png
│       └── aionics_data_model.png
│
├── README.md
└── LICENSE
```

---

### 👨🏽‍💻 About Me

Hi, I’m **Peter Takyi Ohemeng** — a **petroleum engineer and environmental management professional** building strong expertise in **data analytics, business intelligence, and data engineering**.

🌍 I aspire to become an **environmental data analyst**, using data to identify environmental risks, improve operational performance, and support smarter decision-making across the energy and extractive industries.

⚙️ I am particularly interested in finding the right balance between resource development and environmental responsibility. My long-term goal is to help organisations derive the safest and fullest possible benefits from extractive activities while protecting the environment and the communities that depend on it.

📊 Through projects like this, I am developing practical skills in **SQL, data warehousing, dimensional modelling, ETL development, data-quality testing, and analytics reporting** — transforming raw operational data into reliable insights that support better safety, business, and environmental decisions.

> 🌱 **My mission:** To combine engineering knowledge, environmental awareness, and data-driven insights to contribute to a safer, smarter, and more sustainable future.

---

## License

This project is licensed under the [MIT License](LICENSE).

You are free to use, modify, and share this project with proper attribution.
