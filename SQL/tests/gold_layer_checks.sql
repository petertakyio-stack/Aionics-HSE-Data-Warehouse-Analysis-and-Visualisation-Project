/*
===============================================================================
Gold Layer Data Quality Checks
===============================================================================

Purpose:
    Validate the structure and relationships of the Gold star schema after
    creating the dimension and fact views.

Checks:
    - Dimension key uniqueness and completeness
    - Calendar business-key uniqueness
    - Fact grain and event ID uniqueness
    - Row-count reconciliation with Silver
    - Fact-to-dimension key completeness
    - Fact-to-dimension referential integrity

Expected Result:
    Unless otherwise stated, exception queries should return no rows.
===============================================================================
*/


-- ===================================================================
-- 1. Check dimension keys for duplicates or NULLs
-- Expected: No rows
-- ===================================================================

SELECT 'dim_calendar' AS view_name, CAST(calendar_key AS VARCHAR(255)) AS dimension_key, COUNT(*) AS duplicate_count
FROM gold.dim_calendar GROUP BY calendar_key HAVING COUNT(*) > 1 OR calendar_key IS NULL

UNION ALL

SELECT 'dim_cause_reference', CAST(cause_reference_key AS VARCHAR(255)), COUNT(*)
FROM gold.dim_cause_reference GROUP BY cause_reference_key HAVING COUNT(*) > 1 OR cause_reference_key IS NULL

UNION ALL

SELECT 'dim_equipment', CAST(equipment_key AS VARCHAR(255)), COUNT(*)
FROM gold.dim_equipment GROUP BY equipment_key HAVING COUNT(*) > 1 OR equipment_key IS NULL

UNION ALL

SELECT 'dim_personnel', CAST(personnel_key AS VARCHAR(255)), COUNT(*)
FROM gold.dim_personnel GROUP BY personnel_key HAVING COUNT(*) > 1 OR personnel_key IS NULL

UNION ALL

SELECT 'dim_sites', CAST(site_key AS VARCHAR(255)), COUNT(*)
FROM gold.dim_sites GROUP BY site_key HAVING COUNT(*) > 1 OR site_key IS NULL

UNION ALL

SELECT 'dim_work_activities', CAST(work_activity_key AS VARCHAR(255)), COUNT(*)
FROM gold.dim_work_activities GROUP BY work_activity_key HAVING COUNT(*) > 1 OR work_activity_key IS NULL;


-- ===================================================================
-- 2. Check calendar business key for duplicates or NULLs
-- Expected: No rows
-- ===================================================================

SELECT date_id, COUNT(*) AS duplicate_count
FROM gold.dim_calendar
GROUP BY date_id
HAVING COUNT(*) > 1 OR date_id IS NULL;


-- ===================================================================
-- 3. Check fact grain and event ID uniqueness
-- Expected: No rows
-- ===================================================================

SELECT 'event_record_key' AS column_name, CAST(event_record_key AS VARCHAR(255)) AS key_value, COUNT(*) AS duplicate_count
FROM gold.fact_event_records GROUP BY event_record_key HAVING COUNT(*) > 1 OR event_record_key IS NULL

UNION ALL

SELECT 'event_id', CAST(event_id AS VARCHAR(255)), COUNT(*)
FROM gold.fact_event_records GROUP BY event_id HAVING COUNT(*) > 1 OR event_id IS NULL;


-- ===================================================================
-- 4. Reconcile Gold row counts with Silver
-- Expected: expected_rows = gold_rows
-- ===================================================================

SELECT 'dim_calendar' AS view_name, (SELECT COUNT(*) FROM silver.calendar) AS expected_rows, COUNT(*) AS gold_rows
FROM gold.dim_calendar

UNION ALL

SELECT 'dim_cause_reference', (SELECT COUNT(*) FROM silver.cause_reference), COUNT(*)
FROM gold.dim_cause_reference

UNION ALL

SELECT 'dim_equipment', (SELECT COUNT(*) FROM silver.equipment), COUNT(*)
FROM gold.dim_equipment

UNION ALL

SELECT 'dim_personnel', (SELECT COUNT(*) FROM silver.personnel), COUNT(*)
FROM gold.dim_personnel

UNION ALL

SELECT 'dim_sites', (SELECT COUNT(*) FROM silver.sites), COUNT(*)
FROM gold.dim_sites

UNION ALL

SELECT 'dim_work_activities', (SELECT COUNT(*) FROM silver.work_activities), COUNT(*)
FROM gold.dim_work_activities

UNION ALL

SELECT 'fact_event_records', (SELECT COUNT(*) FROM silver.event_records), COUNT(*)
FROM gold.fact_event_records;


-- ===================================================================
-- 5. Check for missing dimension keys in the fact view
-- Expected: No rows
-- ===================================================================

SELECT
    event_record_key,
    calendar_key,
    site_key,
    personnel_key,
    equipment_key,
    work_activity_key,
    cause_reference_key
FROM gold.fact_event_records
WHERE calendar_key IS NULL
    OR site_key IS NULL
    OR personnel_key IS NULL
    OR equipment_key IS NULL
    OR work_activity_key IS NULL
    OR cause_reference_key IS NULL;


-- ===================================================================
-- 6. Check fact-to-dimension referential integrity
-- Expected: No rows
-- ===================================================================

SELECT
    f.event_record_key,
    CASE WHEN c.calendar_key IS NULL THEN f.calendar_key END AS invalid_calendar_key,
    CASE WHEN s.site_key IS NULL THEN f.site_key END AS invalid_site_key,
    CASE WHEN p.personnel_key IS NULL THEN f.personnel_key END AS invalid_personnel_key,
    CASE WHEN eq.equipment_key IS NULL THEN f.equipment_key END AS invalid_equipment_key,
    CASE WHEN w.work_activity_key IS NULL THEN f.work_activity_key END AS invalid_work_activity_key,
    CASE WHEN cr.cause_reference_key IS NULL THEN f.cause_reference_key END AS invalid_cause_reference_key
FROM gold.fact_event_records f
LEFT JOIN gold.dim_calendar c ON f.calendar_key = c.calendar_key
LEFT JOIN gold.dim_sites s ON f.site_key = s.site_key
LEFT JOIN gold.dim_personnel p ON f.personnel_key = p.personnel_key
LEFT JOIN gold.dim_equipment eq ON f.equipment_key = eq.equipment_key
LEFT JOIN gold.dim_work_activities w ON f.work_activity_key = w.work_activity_key
LEFT JOIN gold.dim_cause_reference cr ON f.cause_reference_key = cr.cause_reference_key
WHERE c.calendar_key IS NULL
    OR s.site_key IS NULL
    OR p.personnel_key IS NULL
    OR eq.equipment_key IS NULL
    OR w.work_activity_key IS NULL
    OR cr.cause_reference_key IS NULL;