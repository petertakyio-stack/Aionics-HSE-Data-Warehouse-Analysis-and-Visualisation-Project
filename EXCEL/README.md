# Aionics Solutions HSE Excel Analysis & Validation

## Project Overview

This project demonstrates the use of **Microsoft Excel for Health, Safety and Environment (HSE) data analysis, validation, investigation, and management reporting**.

The workbook contains **14,996 fictional HSE event records** and uses **Power Query, PivotTables, Excel formulas, matrix analysis, Pareto analysis, conditional formatting, and management summary tables** to examine patterns across incidents, sites, personnel, equipment, work activities, causes, and time.

The objective of this Excel project was not simply to produce charts, but to demonstrate how Excel can be used to:

- Prepare analytical datasets with Power Query
- Validate HSE data before analysis
- Perform structured exploratory analysis
- Investigate relationships between operational and HSE variables
- Identify recurring root causes
- Apply Pareto analysis for prioritisation
- Compare HSE performance across operating sites
- Produce management-level analytical summaries
- Generate findings that can support further HSE investigation and decision-making

> **Note:** Aionics Solutions and the HSE dataset used in this project are fictional and were created solely for learning and portfolio development.
---

## Excel Workbook

📊 [`Aionics_HSE_Analysis_and_Validation.xlsx`](./Aionics_HSE_Analysis_and_Validation.xlsx)

---

# Data Preparation with Power Query

Power Query was used to prepare the analytical datasets before performing the Excel analysis.

Key transformations included:

- Reviewing and assigning appropriate data types
- Preserving meaningful blank and NULL values instead of automatically replacing them with zero
- Rounding `years_experience` to two decimal places
- Creating readable employee age groups
- Creating equipment age groups
- Preserving HSE abbreviations during text formatting
- Creating analytical factor profiles
- Creating risk and permit profiles for work activities
- Merging event records with related analytical tables
- Expanding relevant attributes from the calendar, site, personnel, equipment, work-activity, and cause-reference datasets
- Creating a consolidated **Merged HSE Table** for cross-dimensional analysis

The merged dataset made it possible to analyse event measures alongside descriptive attributes

---

## Data Validation

Key HSE measures were reconciled before analysis.

<p align="center">
  <img src="docs/Data%20Validation%20Summary.png" alt="Data Validation Summary" width="100%">
</p>

The validation process helped identify and correct data-type and rounding issues before analysis.
The major HSE measures reconciled successfully between the reference results and Excel.

A negligible precision difference was observed for downtime despite both values displaying as **156,425.41 hours**. This was identified as a rounding/floating-point precision issue rather than a material difference in the underlying data.

The validation stage was particularly useful for identifying and correcting inappropriate data-type and rounding transformations before proceeding with the main analysis.


---

## Exploratory Analysis

PivotTables were used to explore HSE events across:

- Event type, severity, and process safety tier
- Year, quarter, month, and day
- Root and immediate causes
- Sites, countries, and operation types
- Employment type, department, and age group
- Equipment criticality, age, and asset type
- Work activity, work type, shift, and permit/risk profile

<p align="center">
  <img src="docs/Pivot%20Tables.png" alt="Pivot Table Summary" width="100%">
</p>

---

## Matrix Investigation

Cross-tab PivotTables were used to investigate relationships such as:

- Event Type × Site
- Event Type × Employee Age Group
- Event Type × Equipment Criticality
- Asset Type × Equipment Criticality
- Training Status × Severity
- Shift × Equipment Criticality

<p align="center">
  <img src="docs/Matrix%20Investigation%20Tables.png" alt="Matrix Investigation Tables" width="100%">
</p>

---

## Root Cause Pareto Analysis

A Pareto analysis was used to rank root causes by frequency and cumulative contribution.

<p align="center">
  <img src="docs/Pareto%20Analysis.png" alt="Root Cause Pareto Analysis" width="100%">
</p>

The highest-frequency root causes included:

- Lifting Plan / Control Deficiency — 805 events
- Fleet Maintenance Deficiency — 787
- Training Assurance Gap — 730
- Construction Planning Deficiency — 636
- LOTO / Isolation Control Weakness — 630

An important finding from the Pareto analysis is that the events are **not dominated by only a very small number of root causes**.

The top five root causes collectively account for only **23.93%** of recorded events.

The cumulative percentage does not exceed approximately 80% until **Weak Procedure Compliance**, the 22nd ranked root cause, where the cumulative contribution reaches **80.79%**.

This indicates a relatively **distributed root-cause profile** rather than a classic situation in which a small number of causes account for most events.

From an HSE-management perspective, this suggests that improvement efforts may require a broader programme addressing several recurring control weaknesses rather than focusing on only two or three causes.

---

## Management Analysis

A site-level management table was created to compare:

<p align="center">
  <img src="docs/Management%20Analysis%20Tables.png" alt="Management Analysis Table" width="100%">
</p>

---

## Key Analytical Findings

- **Near Miss** was the most common event type with **3,856 events**.
- **Unsafe Conditions** were also prominent with **2,650 events**.
- **Management System** was the largest root-cause category with **4,096 events**.
- **Deepwater Alpha FPSO** recorded the highest total event count at **1,720**.
- **Delta Drilling Site** had the highest recordable-event percentage at **17.49%**.
- **Deepwater Bravo Platform** recorded the highest fatality count at **6** and the highest total incident cost at approximately **$89.27 million**.
- **Western Gas Processing Plant** recorded the highest spill volume at approximately **1.19 million litres** and the highest LTI count at **43**.
- Day and night event volumes were almost identical: **7,451 vs 7,545**.
- The Pareto analysis showed that HSE root causes were **widely distributed**, requiring roughly 22 causes to exceed 80% cumulative contribution.
- Several dimensions contain substantial **Unknown** categories, particularly personnel and equipment, which should be considered when interpreting results.

> These findings identify patterns in the fictional dataset and should not be interpreted as proof of causation.

---

## Excel Skills Demonstrated

- Power Query
- Data transformation
- Query merging and expansion
- PivotTables
- Matrix analysis
- Data validation and reconciliation
- Excel formulas
- Percentage calculations
- Pareto analysis
- Combination charts
- Conditional formatting
- HSE management reporting
- Exploratory data analysis

---

## Project Structure

```text
EXCEL/
│
├── Aionics_HSE_Analysis_and_Validation.xlsx
├── README.md
└── docs/
    ├── Data Validation Summary.png
    ├── Management Analysis Tables.png
    ├── Matrix Investigation Tables.png
    ├── Pareto Analysis.png
    └── Pivot Tables.png
```

---

## Disclaimer

**Aionics Solutions** and all HSE data used in this project are fictional.

The project was developed solely for **educational and portfolio purposes**.
