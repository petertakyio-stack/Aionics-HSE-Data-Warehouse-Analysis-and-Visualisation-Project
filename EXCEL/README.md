# Aionics HSE Excel Analysis and Validation

## Overview

This workbook is the **Excel analysis layer** of the **Aionics Solutions HSE Data Warehouse Analysis and Visualisation Project**. It extends the SQL Server data warehouse by using Microsoft Excel and Power Query to validate warehouse outputs, perform exploratory HSE analysis, investigate relationships across operational dimensions, and prepare management-level summaries before the final reporting layer is developed in Power BI.

The underlying HSE dataset is **fictional** and was created for learning and portfolio purposes.

**Workbook:** [`Aionics_HSE_Analysis_and_Validation.xlsx`](Aionics_HSE_Analysis_and_Validation.xlsx)

**Full project repository:**  
https://github.com/petertakyio-stack/Aionics-HSE-Data-Warehouse-Analysis-and-Visualisation-Project

---

## Role of Excel in the Project

Excel is intentionally used as an **analysis and validation layer**, rather than as a duplicate of the final Power BI dashboard.

The overall project workflow is:

```text
CSV Source Data
      ↓
SQL Server
Bronze → Silver → Gold
      ↓
Excel
Validation → Power Query → Exploratory Analysis
      ↓
Power BI
Interactive KPI Reporting and Visualisation
```

Within this workflow:

- **SQL Server** handles data ingestion, cleansing, standardisation, dimensional modelling, and creation of analytics-ready Gold views.
- **Excel** validates SQL results, enriches the analytical data with Power Query, performs exploratory analysis, Pareto analysis, investigation matrices, and site-level management analysis.
- **Power BI** serves as the final interactive reporting and visualisation layer.

---

## Data Source

The workbook consumes the Gold-layer fact and dimension views created in SQL Server:

```text
gold.fact_event_records
gold.dim_calendar
gold.dim_sites
gold.dim_personnel
gold.dim_equipment
gold.dim_work_activities
gold.dim_cause_reference
```

The Gold layer follows a star-schema design centred on `gold.fact_event_records`.

Excel retains the individual Gold datasets and also uses Power Query to create analysis-ready versions and a merged HSE dataset for cross-dimensional analysis.

---

## Workbook Architecture

The workbook contains **20 worksheets**, organised into analysis, Power Query, and source-data layers.

### Primary Analysis Worksheets

| Worksheet | Purpose |
|---|---|
| **Data Validation Summary** | Reconciles key HSE measures between SQL Server and Excel |
| **Management Analysis Table** | Provides site-level management measures covering event frequency, safety, environmental, financial, and operational impact |
| **Pivot Summary** | Provides broad exploratory analysis across event, calendar, cause, site, personnel, equipment, and work-activity dimensions |
| **Matrix Investigation Tables** | Uses cross-tab analysis to investigate relationships between HSE variables |
| **Root Cause - Pareto Analysis** | Ranks root causes by event frequency and tracks cumulative contribution |
| **Merged HSE Table** | Flat analytical dataset created by combining the event fact data with relevant dimension attributes |

### Power Query Worksheets

```text
pq_event_records
pq_calendar
pq_sites
pq_personnel
pq_equipment
pq_work_activities
pq_cause_reference
```

### Gold Source Worksheets

```text
gold.fact_event_records
gold.dim_calendar
gold.dim_sites
gold.dim_personnel
gold.dim_equipment
gold.dim_work_activities
gold.dim_cause_reference
```

---

## 1. Data Validation and Reconciliation

The **Data Validation Summary** independently recalculates major HSE measures in Excel and compares them with SQL Server results.

The purpose is to confirm that data imported and transformed in Excel remains consistent with the SQL Gold layer.

| Metric | Validated Result |
|---|---:|
| Total Events | 14,996 |
| Recordable Events | 2,426 |
| Lost Time Injuries | 377 |
| Fatalities | 35 |
| Days Lost | 11,542 |
| Restricted Days | 11,967 |
| Spill Volume | 8,644,254.30 L |
| Incident Cost | $656,979,214.95 |
| Downtime | 156,425.41 hours |
| Regulator Reportable Events | 2,539 |

The workbook calculates the difference between SQL and Excel results and assigns a **Pass/Fail reconciliation status**.

> A negligible floating-point precision difference occurs in the downtime reconciliation. The variance is approximately `3.2 × 10^-10` hours and is documented in the workbook as a rounding/precision effect rather than a material data difference.

---

## 2. Power Query Data Preparation

Power Query is used to prepare the SQL Gold data for Excel analysis without repeating the core cleansing already completed in SQL Server.

Key Excel-side preparation includes:

- Confirming appropriate data types
- Preserving meaningful `NULL` values rather than replacing missing values indiscriminately with zero
- Creating analysis-friendly age groupings
- Creating equipment age groups
- Creating HSE factor profiles
- Creating risk/permit analytical profiles
- Combining dimension attributes with event records for cross-dimensional analysis

The resulting **Merged HSE Table** contains event-level measures together with attributes such as:

```text
Date and calendar attributes
Site and location attributes
Personnel and employment attributes
Equipment characteristics
Work activity and shift information
Immediate and root cause information
HSE factor profiles
Event type and severity
Recordable and lost-time flags
Fatalities and lost/restricted days
Spill volume
Incident cost
Downtime
Regulatory-reporting status
```

This flattened analytical table supports PivotTable analysis without altering the underlying SQL star schema.

---

## 3. Exploratory HSE Analysis

The **Pivot Summary** provides a structured exploratory review of the HSE dataset.

The workbook analyses event frequency across areas such as:

### Event Summary

- Event type
- Severity classification
- Process safety tier

### Calendar Summary

- Year
- Quarter
- Month
- Day of week

### Cause Analysis

- Root cause category
- Immediate cause category
- HSE factor profile

### Site Summary

- Site
- Country
- Facility type
- Operation type

### Personnel Summary

- Employment type
- Contractor company
- Department
- Employee age group

### Equipment Summary

- Equipment criticality
- Equipment age group
- Asset type

### Work Activity Summary

- Activity category
- Work type
- Shift
- Risk/permit profile

The workbook contains **34 PivotTables** across the exploratory and investigation analysis areas.

---

## 4. Management Analysis Table

The **Management Analysis Table** provides a consolidated site-level view of key HSE outcomes.

Measures include:

| Measure | Purpose |
|---|---|
| **Event Count** | Overall number of HSE events |
| **Recordable Incidents** | Number of recordable HSE events |
| **Recordable %** | Recordable incidents as a percentage of all events |
| **Regulatory Reportable Incidents** | Events requiring regulatory reporting |
| **Fatalities** | Total fatalities |
| **LTIs** | Lost Time Injuries |
| **Days Lost** | Total workdays lost |
| **Restricted Days** | Total restricted-work days |
| **Downtime Hours** | Operational downtime resulting from events |
| **Downtime per Event** | Average downtime associated with each event |
| **Spill Volume (L)** | Environmental spill/release volume |
| **Incident Cost (USD)** | Total estimated incident cost |
| **Incident Cost per Event (USD)** | Average incident cost per HSE event |

This table allows management to compare sites across **event frequency, injury severity, environmental impact, operational disruption, regulatory significance, and financial impact**.

---

## 5. Investigation Matrices

The **Matrix Investigation Tables** move beyond simple one-dimensional event counts and examine relationships between HSE variables.

The cross-tab analysis includes combinations involving:

- Event type and operating site
- Event type and personnel age grouping
- Event type and equipment criticality
- Equipment characteristics and criticality
- Training status and event severity
- Shift-related event patterns

These investigation matrices are designed to identify relationships that may require deeper analysis rather than simply ranking categories by frequency.

---

## 6. Root Cause Pareto Analysis

A dedicated **Root Cause - Pareto Analysis** ranks specific root causes from highest to lowest event count.

The analysis contains:

```text
Root Cause
Event Count
% of Events
Cumulative %
```

The cumulative percentage is used to identify the root causes that collectively account for the majority of recorded HSE events.

The workbook also includes a Pareto chart combining:

- **Event Count** as columns
- **Cumulative %** as a line
- An **80% reference threshold** for prioritisation

Examples of the highest-frequency root causes in the dataset include:

| Root Cause | Event Count | Share of Events |
|---|---:|---:|
| Lifting Plan / Control Deficiency | 805 | 5.37% |
| Fleet Maintenance Deficiency | 787 | 5.25% |
| Training Assurance Gap | 730 | 4.87% |
| Construction Planning Deficiency | 636 | 4.24% |
| LOTO / Isolation Control Weakness | 630 | 4.20% |

The Pareto analysis is used as a **prioritisation tool**, not as proof that frequency alone represents overall HSE risk. Severity, fatalities, cost, downtime, and environmental impact must also be considered.

---

## Key HSE Measures Used

The Excel analysis uses the following measures from the fact dataset:

```text
Event Count
Recordable Events
Lost Time Injuries
Fatality Count
Days Lost
Restricted Days
Spill Volume (L)
Incident Cost (USD)
Downtime Hours
Regulator Reportable Events
```

Additional management calculations include:

```text
Recordable %
Downtime per Event
Incident Cost per Event
% of Events
Cumulative %
```

> Exposure-based safety indicators such as TRIR and LTIFR are not calculated because the current dataset does not contain workforce exposure hours. These metrics should not be estimated without a valid exposure denominator.

---

## Refresh Workflow

Where the SQL connection is available, the workbook can be refreshed when the underlying warehouse changes.

```text
Update SQL Gold Views
        ↓
Refresh Excel SQL Source Data
        ↓
Refresh Power Query
        ↓
Refresh PivotTables / Analysis
        ↓
Review Validation Results
```

A user opening the workbook without access to the original SQL Server connection can still review the saved workbook results, but refreshing the connected data requires access to the relevant SQL Server database and connection configuration.

---

## Skills Demonstrated

This Excel component demonstrates practical experience with:

- Microsoft Excel
- Power Query
- SQL-to-Excel data integration
- Data validation and reconciliation
- Structured tables
- PivotTables
- Cross-tab / matrix analysis
- Pareto analysis
- Combination charts
- Percentage and cumulative analysis
- HSE management reporting
- Exploratory data analysis
- Data-type management
- Missing-value interpretation
- Analytical data preparation
- Dimensional data analysis
- Management-level KPI calculations

---

## Project Value

The workbook demonstrates how Excel can be used effectively between a SQL data warehouse and a Power BI reporting layer.

Rather than duplicating Power BI, Excel is used to:

1. **Validate** the SQL warehouse outputs.
2. **Explore** the HSE data through PivotTables.
3. **Investigate** relationships across dimensions.
4. **Prioritise** root causes through Pareto analysis.
5. **Summarise** site-level HSE performance for management review.
6. **Identify** patterns and questions that can be carried forward into Power BI.

---

## File

[`Aionics_HSE_Analysis_and_Validation.xlsx`](Aionics_HSE_Analysis_and_Validation.xlsx)

---

## Note

**Aionics Solutions** and the HSE dataset used in this project are fictional. The project was created solely for educational, analytical, and portfolio-development purposes.
