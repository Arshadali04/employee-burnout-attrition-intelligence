-- ============================================================================
-- FILE: 04_data_validation.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Data quality validation - nulls, duplicates, ranges, referential
--          integrity, and logical consistency checks
-- ============================================================================

USE employee_analytics;

-- ============================================================================
-- SECTION 1: NULL CHECKS
-- Verify no critical columns contain unexpected NULLs
-- ============================================================================

SELECT '--- NULL CHECKS ---' AS validation_section;

-- Check for NULL values across key columns in fact_employee
SELECT
    SUM(CASE WHEN employee_id IS NULL THEN 1 ELSE 0 END)               AS null_employee_id,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END)                       AS null_age,
    SUM(CASE WHEN attrition IS NULL THEN 1 ELSE 0 END)                 AS null_attrition,
    SUM(CASE WHEN monthly_income IS NULL THEN 1 ELSE 0 END)            AS null_monthly_income,
    SUM(CASE WHEN department_id IS NULL THEN 1 ELSE 0 END)             AS null_department_id,
    SUM(CASE WHEN role_id IS NULL THEN 1 ELSE 0 END)                   AS null_role_id,
    SUM(CASE WHEN workload_score IS NULL THEN 1 ELSE 0 END)            AS null_workload_score,
    SUM(CASE WHEN weekly_hours_worked IS NULL THEN 1 ELSE 0 END)       AS null_weekly_hours,
    SUM(CASE WHEN productivity_score IS NULL THEN 1 ELSE 0 END)        AS null_productivity,
    SUM(CASE WHEN work_model IS NULL THEN 1 ELSE 0 END)                AS null_work_model
FROM fact_employee;

-- ============================================================================
-- SECTION 2: DUPLICATE CHECKS
-- Ensure primary keys are unique
-- ============================================================================

SELECT '--- DUPLICATE CHECKS ---' AS validation_section;

-- Duplicate employee IDs (should return 0)
SELECT
    'fact_employee' AS table_name,
    COUNT(*) - COUNT(DISTINCT employee_id) AS duplicate_count
FROM fact_employee
UNION ALL
SELECT
    'dim_department',
    COUNT(*) - COUNT(DISTINCT department_id)
FROM dim_department
UNION ALL
SELECT
    'dim_job_role',
    COUNT(*) - COUNT(DISTINCT role_id)
FROM dim_job_role;

-- Show actual duplicates if they exist
SELECT employee_id, COUNT(*) AS occurrences
FROM fact_employee
GROUP BY employee_id
HAVING COUNT(*) > 1;

-- ============================================================================
-- SECTION 3: RANGE AND DOMAIN CHECKS
-- Validate that values fall within expected business ranges
-- ============================================================================

SELECT '--- RANGE CHECKS ---' AS validation_section;

-- Age should be between 18 and 70
SELECT 'Age out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE age < 18 OR age > 70;

-- Satisfaction scores must be 1-4
SELECT 'Environment satisfaction out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE environment_satisfaction NOT BETWEEN 1 AND 4;

SELECT 'Job satisfaction out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE job_satisfaction NOT BETWEEN 1 AND 4;

SELECT 'Work-life balance out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE work_life_balance NOT BETWEEN 1 AND 4;

SELECT 'Compensation satisfaction out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE compensation_satisfaction NOT BETWEEN 1 AND 5;

-- Education should be 1-5
SELECT 'Education out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE education NOT BETWEEN 1 AND 5;

-- Performance rating should be 1-4
SELECT 'Performance rating out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE performance_rating NOT BETWEEN 1 AND 4;

-- Weekly hours should be reasonable (20 to 80)
SELECT 'Weekly hours out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE weekly_hours_worked < 20 OR weekly_hours_worked > 80;

-- Monthly income should be positive
SELECT 'Non-positive monthly income' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE monthly_income <= 0;

-- Tenure consistency: years_in_current_role <= years_at_company
SELECT 'Role tenure exceeds company tenure' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE years_in_current_role > years_at_company;

-- Tenure consistency: years_at_company <= total_working_years
SELECT 'Company tenure exceeds total experience' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE years_at_company > total_working_years;

-- Productivity score should be 1-5 (same scale as other synthetic scores)
SELECT 'Productivity score out of range' AS check_name, COUNT(*) AS violations
FROM fact_employee
WHERE productivity_score NOT BETWEEN 1 AND 5;

-- ============================================================================
-- SECTION 4: REFERENTIAL INTEGRITY CHECKS
-- Verify all foreign keys point to valid dimension records
-- ============================================================================

SELECT '--- REFERENTIAL INTEGRITY CHECKS ---' AS validation_section;

-- Orphan department references
SELECT 'Orphan department_id in fact_employee' AS check_name, COUNT(*) AS violations
FROM fact_employee f
LEFT JOIN dim_department d ON f.department_id = d.department_id
WHERE d.department_id IS NULL;

-- Orphan role references
SELECT 'Orphan role_id in fact_employee' AS check_name, COUNT(*) AS violations
FROM fact_employee f
LEFT JOIN dim_job_role r ON f.role_id = r.role_id
WHERE r.role_id IS NULL;

-- Cross-dimension consistency: role's department should match employee's department
SELECT 'Role-department mismatch' AS check_name, COUNT(*) AS violations
FROM fact_employee f
JOIN dim_job_role r ON f.role_id = r.role_id
WHERE f.department_id != r.department_id;

-- ============================================================================
-- SECTION 5: DISTRIBUTION AND OUTLIER CHECKS
-- Verify data distributions are plausible
-- ============================================================================

SELECT '--- DISTRIBUTION CHECKS ---' AS validation_section;

-- Attrition rate sanity check (typical is 10-20%)
SELECT
    attrition,
    COUNT(*) AS employee_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM fact_employee
GROUP BY attrition;

-- Income distribution by job level (should increase with level)
SELECT
    job_level,
    COUNT(*) AS headcount,
    MIN(monthly_income) AS min_income,
    ROUND(AVG(monthly_income), 0) AS avg_income,
    MAX(monthly_income) AS max_income
FROM fact_employee
GROUP BY job_level
ORDER BY job_level;

-- Department headcount distribution
SELECT
    d.department_name,
    COUNT(*) AS headcount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_employee), 1) AS pct_of_total
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
GROUP BY d.department_name
ORDER BY headcount DESC;

-- ============================================================================
-- SECTION 6: SUMMARY VALIDATION REPORT
-- ============================================================================

SELECT '--- VALIDATION SUMMARY ---' AS validation_section;

SELECT
    (SELECT COUNT(*) FROM fact_employee) AS total_employees,
    (SELECT COUNT(*) FROM dim_department) AS total_departments,
    (SELECT COUNT(*) FROM dim_job_role) AS total_roles,
    (SELECT MIN(age) FROM fact_employee) AS min_age,
    (SELECT MAX(age) FROM fact_employee) AS max_age,
    (SELECT MIN(monthly_income) FROM fact_employee) AS min_income,
    (SELECT MAX(monthly_income) FROM fact_employee) AS max_income;
