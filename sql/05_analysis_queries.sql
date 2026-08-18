-- ============================================================================
-- FILE: 05_analysis_queries.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Analytical queries demonstrating JOINs, CTEs, window functions,
--          CASE expressions, GROUP BY/HAVING for business insights
-- ============================================================================

USE employee_analytics;

-- ============================================================================
-- QUERY 1: ATTRITION RATE BY DEPARTMENT
-- Business Question: Which departments have the highest attrition rates,
-- and how do they compare to the company-wide average?
-- ============================================================================

WITH dept_attrition AS (
    SELECT
        d.department_name,
        COUNT(*) AS total_employees,
        SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
        ROUND(
            SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
        ) AS attrition_rate_pct
    FROM fact_employee f
    JOIN dim_department d ON f.department_id = d.department_id
    GROUP BY d.department_name
),
company_avg AS (
    SELECT ROUND(
        SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS company_attrition_rate
    FROM fact_employee
)
SELECT
    da.department_name,
    da.total_employees,
    da.attrition_count,
    da.attrition_rate_pct,
    ca.company_attrition_rate,
    ROUND(da.attrition_rate_pct - ca.company_attrition_rate, 1) AS variance_from_avg,
    CASE
        WHEN da.attrition_rate_pct > ca.company_attrition_rate * 1.2 THEN 'HIGH RISK'
        WHEN da.attrition_rate_pct < ca.company_attrition_rate * 0.8 THEN 'LOW RISK'
        ELSE 'AVERAGE'
    END AS risk_classification
FROM dept_attrition da
CROSS JOIN company_avg ca
ORDER BY da.attrition_rate_pct DESC;

-- ============================================================================
-- QUERY 2: SALARY ANALYSIS BY ROLE WITH PERCENTILE RANKING
-- Business Question: How does each employee's salary compare within their role,
-- and which roles have the widest pay disparity?
-- ============================================================================

SELECT
    r.role_name,
    f.employee_id,
    f.monthly_income,
    ROUND(AVG(f.monthly_income) OVER (PARTITION BY f.role_id), 0) AS role_avg_income,
    MIN(f.monthly_income) OVER (PARTITION BY f.role_id) AS role_min_income,
    MAX(f.monthly_income) OVER (PARTITION BY f.role_id) AS role_max_income,
    DENSE_RANK() OVER (PARTITION BY f.role_id ORDER BY f.monthly_income DESC) AS income_rank_in_role,
    ROUND(
        PERCENT_RANK() OVER (PARTITION BY f.role_id ORDER BY f.monthly_income) * 100, 0
    ) AS percentile_within_role,
    ROUND(
        (f.monthly_income - AVG(f.monthly_income) OVER (PARTITION BY f.role_id))
        / NULLIF(STDDEV(f.monthly_income) OVER (PARTITION BY f.role_id), 0), 2
    ) AS salary_z_score
FROM fact_employee f
JOIN dim_job_role r ON f.role_id = r.role_id
ORDER BY r.role_name, f.monthly_income DESC;

-- ============================================================================
-- QUERY 3: OVERTIME IMPACT ON ATTRITION AND SATISFACTION
-- Business Question: Does overtime significantly correlate with higher attrition?
-- How does it affect satisfaction and productivity?
-- ============================================================================

SELECT
    f.over_time,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(f.work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(f.environment_satisfaction), 2) AS avg_env_satisfaction,
    ROUND(AVG(f.workload_score), 2) AS avg_workload_score,
    ROUND(AVG(f.weekly_hours_worked), 1) AS avg_weekly_hours,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
    ROUND(AVG(f.monthly_income), 0) AS avg_income
FROM fact_employee f
GROUP BY f.over_time;

-- Drill down: Overtime impact segmented by department
SELECT
    d.department_name,
    f.over_time,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.workload_score), 2) AS avg_workload,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
GROUP BY d.department_name, f.over_time
HAVING COUNT(*) >= 1
ORDER BY d.department_name, f.over_time;

-- ============================================================================
-- QUERY 4: TENURE PATTERNS AND ATTRITION RISK BY COHORT
-- Business Question: At what tenure points do employees leave most?
-- Is there a "danger zone" in the employee lifecycle?
-- ============================================================================

WITH tenure_cohorts AS (
    SELECT
        f.tenure_band,
        f.years_at_company,
        f.attrition,
        f.monthly_income,
        f.job_satisfaction,
        f.career_growth_perception,
        COUNT(*) OVER (PARTITION BY f.tenure_band) AS cohort_size,
        SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END)
            OVER (PARTITION BY f.tenure_band) AS cohort_attrition
    FROM fact_employee f
)
SELECT DISTINCT
    tenure_band,
    cohort_size,
    cohort_attrition,
    ROUND(cohort_attrition * 100.0 / cohort_size, 1) AS attrition_rate_pct,
    ROUND(AVG(monthly_income) OVER (PARTITION BY tenure_band), 0) AS avg_income,
    ROUND(AVG(job_satisfaction) OVER (PARTITION BY tenure_band), 2) AS avg_satisfaction,
    ROUND(AVG(career_growth_perception) OVER (PARTITION BY tenure_band), 2) AS avg_growth_perception
FROM tenure_cohorts
ORDER BY
    CASE tenure_band
        WHEN 'New (0-1)' THEN 1
        WHEN 'Settling (2-3)' THEN 2
        WHEN 'Established (4-5)' THEN 3
        WHEN 'Veteran (6-10)' THEN 4
        WHEN 'Lifer (10+)' THEN 5
    END;

-- ============================================================================
-- QUERY 5: SEGMENT COMPARISON - WORK MODEL EFFECTIVENESS
-- Business Question: How do Remote, Hybrid, and On-Site employees compare on
-- key performance and well-being metrics?
-- ============================================================================

SELECT
    f.work_model,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
    ROUND(AVG(f.work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(f.job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(f.manager_support_score), 2) AS avg_manager_support,
    ROUND(AVG(f.workload_score), 2) AS avg_workload,
    ROUND(AVG(f.weekly_hours_worked), 1) AS avg_weekly_hours,
    ROUND(AVG(f.monthly_income), 0) AS avg_income,
    ROUND(AVG(f.career_growth_perception), 2) AS avg_career_growth
FROM fact_employee f
GROUP BY f.work_model
ORDER BY avg_productivity DESC;

-- ============================================================================
-- QUERY 6: WORKLOAD VS SATISFACTION CORRELATION ANALYSIS
-- Business Question: Is there a tipping point where workload degrades satisfaction?
-- Which employees are in the "high workload, low satisfaction" danger zone?
-- ============================================================================

WITH workload_quartiles AS (
    SELECT
        f.employee_id,
        f.workload_score,
        f.job_satisfaction,
        f.work_life_balance,
        f.attrition,
        f.productivity_score,
        NTILE(4) OVER (ORDER BY f.workload_score) AS workload_quartile
    FROM fact_employee f
)
SELECT
    workload_quartile,
    ROUND(MIN(workload_score), 2) AS min_workload,
    ROUND(MAX(workload_score), 2) AS max_workload,
    COUNT(*) AS headcount,
    ROUND(AVG(job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(productivity_score), 2) AS avg_productivity,
    ROUND(SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct
FROM workload_quartiles
GROUP BY workload_quartile
ORDER BY workload_quartile;

-- Employees in the danger zone: high workload + low satisfaction
SELECT
    f.employee_id,
    r.role_name,
    d.department_name,
    f.workload_score,
    f.weekly_hours_worked,
    f.job_satisfaction,
    f.work_life_balance,
    f.environment_satisfaction,
    f.attrition,
    f.over_time
FROM fact_employee f
JOIN dim_job_role r ON f.role_id = r.role_id
JOIN dim_department d ON f.department_id = d.department_id
WHERE f.workload_score >= 4
  AND (f.job_satisfaction <= 2 OR f.work_life_balance <= 2)
ORDER BY f.workload_score DESC;

-- ============================================================================
-- QUERY 7: TOP ATTRITION RISK EMPLOYEES (COMPOSITE SCORING)
-- Business Question: Which current employees are most likely to leave next,
-- based on a weighted risk model using known attrition factors?
-- ============================================================================

WITH risk_scoring AS (
    SELECT
        f.employee_id,
        r.role_name,
        d.department_name,
        f.attrition,
        f.monthly_income,
        f.years_at_company,
        f.job_satisfaction,
        f.work_life_balance,
        f.over_time,
        f.workload_score,
        f.manager_support_score,
        f.career_growth_perception,
        f.compensation_satisfaction,
        -- Composite risk score (higher = more at risk)
        -- Weights based on known attrition drivers
        (CASE WHEN f.over_time = 'Yes' THEN 20 ELSE 0 END) +
        (CASE WHEN f.job_satisfaction = 1 THEN 20 WHEN f.job_satisfaction = 2 THEN 10 ELSE 0 END) +
        (CASE WHEN f.work_life_balance = 1 THEN 15 WHEN f.work_life_balance = 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.career_growth_perception <= 2 THEN 15 ELSE 0 END) +
        (CASE WHEN f.compensation_satisfaction <= 2 THEN 12 ELSE 0 END) +
        (CASE WHEN f.manager_support_score < 3.0 THEN 10 ELSE 0 END) +
        (CASE WHEN f.years_since_last_promotion >= 5 THEN 10 ELSE 0 END) +
        (CASE WHEN f.workload_score >= 4 THEN 10 ELSE 0 END) +
        (CASE WHEN f.years_at_company <= 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.stock_option_level = 0 THEN 5 ELSE 0 END)
        AS risk_score
    FROM fact_employee f
    JOIN dim_job_role r ON f.role_id = r.role_id
    JOIN dim_department d ON f.department_id = d.department_id
)
SELECT
    employee_id,
    role_name,
    department_name,
    attrition AS already_left,
    risk_score,
    RANK() OVER (ORDER BY risk_score DESC) AS risk_rank,
    CASE
        WHEN risk_score >= 60 THEN 'CRITICAL'
        WHEN risk_score >= 40 THEN 'HIGH'
        WHEN risk_score >= 25 THEN 'MODERATE'
        ELSE 'LOW'
    END AS risk_tier,
    monthly_income,
    over_time,
    job_satisfaction,
    work_life_balance,
    career_growth_perception,
    manager_support_score
FROM risk_scoring
ORDER BY risk_score DESC
LIMIT 20;

-- ============================================================================
-- QUERY 8: SALARY BAND MOVEMENT AND INCOME GROWTH ANALYSIS
-- Business Question: Are employees in lower salary bands receiving adequate
-- salary hikes, or is the gap widening over time?
-- ============================================================================

SELECT
    f.salary_band,
    f.experience_band,
    COUNT(*) AS headcount,
    ROUND(AVG(f.monthly_income), 0) AS avg_income,
    ROUND(AVG(f.percent_salary_hike), 1) AS avg_salary_hike_pct,
    ROUND(AVG(f.compensation_satisfaction), 2) AS avg_comp_satisfaction,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    RANK() OVER (ORDER BY AVG(f.percent_salary_hike) DESC) AS hike_rank
FROM fact_employee f
GROUP BY f.salary_band, f.experience_band
HAVING COUNT(*) >= 1
ORDER BY
    CASE f.salary_band
        WHEN 'Low' THEN 1 WHEN 'Below Average' THEN 2 WHEN 'Average' THEN 3
        WHEN 'Above Average' THEN 4 WHEN 'High' THEN 5
    END,
    CASE f.experience_band
        WHEN 'Entry (0-2)' THEN 1 WHEN 'Early (3-5)' THEN 2 WHEN 'Mid (6-10)' THEN 3
        WHEN 'Senior (11-20)' THEN 4 WHEN 'Expert (20+)' THEN 5
    END;

-- ============================================================================
-- QUERY 9: MANAGER SUPPORT IMPACT - LAG/LEAD ANALYSIS
-- Business Question: How does manager support compare across job levels,
-- and what is the step-change in satisfaction as support increases?
-- ============================================================================

WITH manager_impact AS (
    SELECT
        f.job_level,
        ROUND(AVG(f.manager_support_score), 2) AS avg_manager_support,
        ROUND(AVG(f.job_satisfaction), 2) AS avg_satisfaction,
        ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
        ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate,
        COUNT(*) AS headcount
    FROM fact_employee f
    GROUP BY f.job_level
)
SELECT
    job_level,
    headcount,
    avg_manager_support,
    avg_satisfaction,
    avg_productivity,
    attrition_rate,
    LAG(avg_manager_support) OVER (ORDER BY job_level) AS prev_level_support,
    ROUND(
        avg_manager_support - LAG(avg_manager_support) OVER (ORDER BY job_level), 2
    ) AS support_change_vs_prev_level,
    LEAD(attrition_rate) OVER (ORDER BY job_level) AS next_level_attrition,
    ROUND(
        attrition_rate - LEAD(attrition_rate) OVER (ORDER BY job_level), 1
    ) AS attrition_diff_vs_next_level
FROM manager_impact
ORDER BY job_level;

-- ============================================================================
-- QUERY 10: RUNNING TOTAL - CUMULATIVE ATTRITION COST BY DEPARTMENT
-- Business Question: If we estimate replacement cost at 6x monthly salary,
-- what is the cumulative financial impact of attrition per department?
-- ============================================================================

WITH attrition_costs AS (
    SELECT
        d.department_name,
        f.employee_id,
        f.monthly_income,
        f.monthly_income * 6 AS estimated_replacement_cost,
        f.years_at_company
    FROM fact_employee f
    JOIN dim_department d ON f.department_id = d.department_id
    WHERE f.attrition = 'Yes'
)
SELECT
    department_name,
    employee_id,
    monthly_income,
    estimated_replacement_cost,
    SUM(estimated_replacement_cost) OVER (
        PARTITION BY department_name
        ORDER BY years_at_company
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_dept_cost,
    SUM(estimated_replacement_cost) OVER (
        ORDER BY department_name, years_at_company
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_total_cost
FROM attrition_costs
ORDER BY department_name, years_at_company;

-- Department-level summary of attrition financial impact
SELECT
    d.department_name,
    COUNT(*) AS employees_lost,
    SUM(f.monthly_income * 6) AS total_replacement_cost,
    ROUND(AVG(f.monthly_income * 6), 0) AS avg_replacement_cost_per_exit,
    ROUND(
        SUM(f.monthly_income * 6) * 100.0
        / SUM(SUM(f.monthly_income * 6)) OVER (), 1
    ) AS pct_of_total_attrition_cost
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
WHERE f.attrition = 'Yes'
GROUP BY d.department_name
ORDER BY total_replacement_cost DESC;

-- ============================================================================
-- QUERY 11: MULTI-FACTOR BURNOUT SEGMENTATION
-- Business Question: Can we identify distinct burnout profiles based on
-- workload, hours, satisfaction, and overtime combinations?
-- ============================================================================

SELECT
    CASE
        WHEN f.workload_score = 5 AND f.weekly_hours_worked >= 50 AND f.over_time = 'Yes'
            THEN 'Severe Burnout'
        WHEN f.workload_score >= 4 AND (f.weekly_hours_worked >= 48 OR f.over_time = 'Yes')
            THEN 'Moderate Burnout'
        WHEN f.workload_score >= 3 AND f.work_life_balance <= 2
            THEN 'Early Warning'
        ELSE 'Healthy'
    END AS burnout_segment,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.workload_score), 2) AS avg_workload,
    ROUND(AVG(f.weekly_hours_worked), 1) AS avg_weekly_hours,
    ROUND(AVG(f.job_satisfaction), 2) AS avg_satisfaction,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
    ROUND(AVG(f.manager_support_score), 2) AS avg_manager_support,
    ROUND(AVG(f.monthly_income), 0) AS avg_income
FROM fact_employee f
GROUP BY burnout_segment
ORDER BY attrition_rate_pct DESC;

-- ============================================================================
-- QUERY 12: YEAR-OVER-YEAR COMPARISON USING LAG
-- Business Question: For employees still at the company, how does tenure
-- progression affect key metrics? (Simulated with tenure bands as proxy)
-- ============================================================================

WITH band_metrics AS (
    SELECT
        f.tenure_band,
        CASE f.tenure_band
            WHEN 'New (0-1)' THEN 1
            WHEN 'Settling (2-3)' THEN 2
            WHEN 'Established (4-5)' THEN 3
            WHEN 'Veteran (6-10)' THEN 4
            WHEN 'Lifer (10+)' THEN 5
        END AS band_order,
        ROUND(AVG(f.monthly_income), 0) AS avg_income,
        ROUND(AVG(f.job_satisfaction), 2) AS avg_satisfaction,
        ROUND(AVG(f.career_growth_perception), 2) AS avg_career_growth,
        ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
        COUNT(*) AS headcount
    FROM fact_employee f
    GROUP BY f.tenure_band
)
SELECT
    tenure_band,
    headcount,
    avg_income,
    LAG(avg_income) OVER (ORDER BY band_order) AS prev_band_income,
    ROUND(
        (avg_income - LAG(avg_income) OVER (ORDER BY band_order))
        * 100.0 / NULLIF(LAG(avg_income) OVER (ORDER BY band_order), 0), 1
    ) AS income_growth_pct,
    avg_satisfaction,
    ROUND(avg_satisfaction - LAG(avg_satisfaction) OVER (ORDER BY band_order), 2) AS satisfaction_delta,
    avg_career_growth,
    avg_productivity
FROM band_metrics
ORDER BY band_order;
