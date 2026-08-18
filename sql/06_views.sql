-- ============================================================================
-- FILE: 06_views.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Analytical views for dashboards, reports, and downstream consumers
-- ============================================================================

USE employee_analytics;

-- ============================================================================
-- VIEW 1: vw_employee_full
-- Denormalized employee view joining all dimensions for easy reporting.
-- Use case: Foundation view for dashboards and ad-hoc analysis.
-- ============================================================================

DROP VIEW IF EXISTS vw_employee_full;

CREATE VIEW vw_employee_full AS
SELECT
    f.employee_id,
    f.age,
    f.attrition,
    f.gender,
    f.marital_status,
    d.department_name,
    r.role_name,
    f.job_level,
    f.education,
    f.education_field,
    f.business_travel,
    f.distance_from_home,
    f.monthly_income,
    f.daily_rate,
    f.hourly_rate,
    f.monthly_rate,
    f.percent_salary_hike,
    f.salary_band,
    f.stock_option_level,
    f.over_time,
    f.weekly_hours_worked,
    f.workload_score,
    f.monthly_meetings,
    f.productivity_score,
    f.job_satisfaction,
    f.environment_satisfaction,
    f.relationship_satisfaction,
    f.compensation_satisfaction,
    f.work_life_balance,
    f.job_involvement,
    f.career_growth_perception,
    f.manager_support_score,
    f.performance_rating,
    f.training_times_last_year,
    f.work_model,
    f.total_working_years,
    f.years_at_company,
    f.years_in_current_role,
    f.years_since_last_promotion,
    f.years_with_curr_manager,
    f.num_companies_worked,
    f.experience_band,
    f.tenure_band
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
JOIN dim_job_role r ON f.role_id = r.role_id;

-- ============================================================================
-- VIEW 2: vw_attrition_summary
-- Aggregated attrition metrics broken down by key segments.
-- Use case: Executive dashboard showing where attrition is concentrated.
-- ============================================================================

DROP VIEW IF EXISTS vw_attrition_summary;

CREATE VIEW vw_attrition_summary AS
SELECT
    d.department_name,
    r.role_name,
    f.work_model,
    f.over_time,
    f.salary_band,
    f.tenure_band,
    COUNT(*) AS total_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    ROUND(
        SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1
    ) AS attrition_rate_pct,
    ROUND(AVG(f.monthly_income), 0) AS avg_income,
    ROUND(AVG(f.job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(f.work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(f.workload_score), 2) AS avg_workload_score,
    SUM(CASE WHEN f.attrition = 'Yes' THEN f.monthly_income * 6 ELSE 0 END) AS estimated_replacement_cost
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
JOIN dim_job_role r ON f.role_id = r.role_id
GROUP BY
    d.department_name,
    r.role_name,
    f.work_model,
    f.over_time,
    f.salary_band,
    f.tenure_band;

-- ============================================================================
-- VIEW 3: vw_department_health
-- Department-level health scorecard with composite metrics.
-- Use case: HR leaders monitoring department-level workforce health.
-- ============================================================================

DROP VIEW IF EXISTS vw_department_health;

CREATE VIEW vw_department_health AS
SELECT
    d.department_name,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(f.environment_satisfaction), 2) AS avg_env_satisfaction,
    ROUND(AVG(f.work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(f.compensation_satisfaction), 2) AS avg_comp_satisfaction,
    ROUND(AVG(f.career_growth_perception), 2) AS avg_career_growth,
    ROUND(AVG(f.manager_support_score), 2) AS avg_manager_support,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity,
    ROUND(AVG(f.workload_score), 2) AS avg_workload,
    ROUND(AVG(f.weekly_hours_worked), 1) AS avg_weekly_hours,
    ROUND(AVG(f.monthly_income), 0) AS avg_income,
    ROUND(AVG(f.years_at_company), 1) AS avg_tenure_years,
    ROUND(AVG(f.training_times_last_year), 1) AS avg_training_sessions,
    SUM(CASE WHEN f.over_time = 'Yes' THEN 1 ELSE 0 END) AS overtime_count,
    ROUND(SUM(CASE WHEN f.over_time = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS overtime_pct,
    -- Composite health score: normalize each variable to 0-1 then scale to 100
    -- job_satisfaction and work_life_balance are 1-4; compensation/career/env vary (1-4 or 1-5)
    ROUND(
        (AVG(f.job_satisfaction)/4.0 + AVG(f.environment_satisfaction)/4.0 +
         AVG(f.work_life_balance)/4.0 + AVG(f.compensation_satisfaction)/5.0 +
         AVG(f.career_growth_perception)/5.0) / 5.0 * 100, 1
    ) AS health_score_out_of_100
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
GROUP BY d.department_name;

-- ============================================================================
-- VIEW 4: vw_salary_bands
-- Salary band analysis with income distribution and progression metrics.
-- Use case: Compensation team reviewing pay equity and band utilization.
-- ============================================================================

DROP VIEW IF EXISTS vw_salary_bands;

CREATE VIEW vw_salary_bands AS
SELECT
    f.salary_band,
    f.experience_band,
    d.department_name,
    COUNT(*) AS headcount,
    MIN(f.monthly_income) AS min_income,
    ROUND(AVG(f.monthly_income), 0) AS avg_income,
    MAX(f.monthly_income) AS max_income,
    MAX(f.monthly_income) - MIN(f.monthly_income) AS income_spread,
    ROUND(AVG(f.percent_salary_hike), 1) AS avg_salary_hike_pct,
    ROUND(AVG(f.compensation_satisfaction), 2) AS avg_comp_satisfaction,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(AVG(f.total_working_years), 1) AS avg_total_experience,
    ROUND(AVG(f.years_at_company), 1) AS avg_tenure,
    ROUND(AVG(f.performance_rating), 2) AS avg_performance_rating,
    SUM(CASE WHEN f.stock_option_level > 0 THEN 1 ELSE 0 END) AS employees_with_stock
FROM fact_employee f
JOIN dim_department d ON f.department_id = d.department_id
GROUP BY f.salary_band, f.experience_band, d.department_name;

-- ============================================================================
-- VIEW 5: vw_risk_segments
-- Employee-level risk segmentation with composite scoring.
-- Use case: HR intervention targeting - identify who needs attention now.
-- ============================================================================

DROP VIEW IF EXISTS vw_risk_segments;

-- Use a subquery so risk_tier can reference the already-computed risk_score
-- without repeating all 10 factor expressions (avoids the prior bug where
-- risk_tier only used 6 of the 10 factors, making it inconsistent with risk_score).
CREATE VIEW vw_risk_segments AS
SELECT
    employee_id,
    department_name,
    role_name,
    age,
    gender,
    marital_status,
    attrition,
    monthly_income,
    years_at_company,
    over_time,
    work_model,
    job_satisfaction,
    work_life_balance,
    compensation_satisfaction,
    career_growth_perception,
    manager_support_score,
    workload_score,
    weekly_hours_worked,
    years_since_last_promotion,
    stock_option_level,
    risk_score,
    CASE
        WHEN risk_score >= 60 THEN 'CRITICAL'
        WHEN risk_score >= 40 THEN 'HIGH'
        WHEN risk_score >= 25 THEN 'MODERATE'
        ELSE 'LOW'
    END AS risk_tier,
    burnout_segment
FROM (
    SELECT
        f.employee_id,
        d.department_name,
        r.role_name,
        f.age,
        f.gender,
        f.marital_status,
        f.attrition,
        f.monthly_income,
        f.years_at_company,
        f.over_time,
        f.work_model,
        f.job_satisfaction,
        f.work_life_balance,
        f.compensation_satisfaction,
        f.career_growth_perception,
        f.manager_support_score,
        f.workload_score,
        f.weekly_hours_worked,
        f.years_since_last_promotion,
        f.stock_option_level,
        -- Risk score: all 10 factors (workload_score is 1-5; threshold 4 = Heavy/Extreme)
        (CASE WHEN f.over_time = 'Yes' THEN 20 ELSE 0 END) +
        (CASE WHEN f.job_satisfaction = 1 THEN 20 WHEN f.job_satisfaction = 2 THEN 10 ELSE 0 END) +
        (CASE WHEN f.work_life_balance = 1 THEN 15 WHEN f.work_life_balance = 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.career_growth_perception <= 2 THEN 15 ELSE 0 END) +
        (CASE WHEN f.compensation_satisfaction <= 2 THEN 12 ELSE 0 END) +
        (CASE WHEN f.manager_support_score < 3 THEN 10 ELSE 0 END) +
        (CASE WHEN f.years_since_last_promotion >= 5 THEN 10 ELSE 0 END) +
        (CASE WHEN f.workload_score >= 4 THEN 10 ELSE 0 END) +
        (CASE WHEN f.years_at_company <= 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.stock_option_level = 0 THEN 5 ELSE 0 END)
        AS risk_score,
        -- Burnout classification (thresholds scaled for 1-5 integer workload_score)
        CASE
            WHEN f.workload_score = 5 AND f.weekly_hours_worked >= 50 AND f.over_time = 'Yes'
                THEN 'Severe Burnout'
            WHEN f.workload_score >= 4 AND (f.weekly_hours_worked >= 48 OR f.over_time = 'Yes')
                THEN 'Moderate Burnout'
            WHEN f.workload_score >= 3 AND f.work_life_balance <= 2
                THEN 'Early Warning'
            ELSE 'Healthy'
        END AS burnout_segment
    FROM fact_employee f
    JOIN dim_department d ON f.department_id = d.department_id
    JOIN dim_job_role r ON f.role_id = r.role_id
) AS scored;

-- ============================================================================
-- VIEW 6: vw_workforce_health
-- Organization-wide workforce health dashboard metrics.
-- Use case: C-suite single-pane view of overall workforce health and trends.
-- ============================================================================

DROP VIEW IF EXISTS vw_workforce_health;

CREATE VIEW vw_workforce_health AS
SELECT
    -- Headcount metrics
    COUNT(*) AS total_headcount,
    SUM(CASE WHEN f.attrition = 'No' THEN 1 ELSE 0 END) AS active_employees,
    SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) AS departed_employees,
    ROUND(SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS overall_attrition_rate_pct,

    -- Demographics
    ROUND(AVG(f.age), 1) AS avg_age,
    ROUND(AVG(f.total_working_years), 1) AS avg_experience_years,
    ROUND(AVG(f.years_at_company), 1) AS avg_tenure_years,

    -- Compensation
    ROUND(AVG(f.monthly_income), 0) AS avg_monthly_income,
    MIN(f.monthly_income) AS min_monthly_income,
    MAX(f.monthly_income) AS max_monthly_income,
    ROUND(AVG(f.percent_salary_hike), 1) AS avg_salary_hike_pct,

    -- Satisfaction scores (all on 1-4 scale)
    ROUND(AVG(f.job_satisfaction), 2) AS avg_job_satisfaction,
    ROUND(AVG(f.environment_satisfaction), 2) AS avg_env_satisfaction,
    ROUND(AVG(f.work_life_balance), 2) AS avg_work_life_balance,
    ROUND(AVG(f.compensation_satisfaction), 2) AS avg_comp_satisfaction,
    ROUND(AVG(f.relationship_satisfaction), 2) AS avg_relationship_satisfaction,
    ROUND(AVG(f.career_growth_perception), 2) AS avg_career_growth,
    ROUND(AVG(f.manager_support_score), 2) AS avg_manager_support,

    -- Workload and performance
    ROUND(AVG(f.workload_score), 2) AS avg_workload_score,
    ROUND(AVG(f.weekly_hours_worked), 1) AS avg_weekly_hours,
    ROUND(AVG(f.productivity_score), 2) AS avg_productivity_score,
    ROUND(AVG(f.performance_rating), 2) AS avg_performance_rating,

    -- Overtime and work model distribution
    SUM(CASE WHEN f.over_time = 'Yes' THEN 1 ELSE 0 END) AS overtime_count,
    ROUND(SUM(CASE WHEN f.over_time = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS overtime_pct,
    SUM(CASE WHEN f.work_model = 'Remote' THEN 1 ELSE 0 END) AS remote_count,
    SUM(CASE WHEN f.work_model = 'Hybrid' THEN 1 ELSE 0 END) AS hybrid_count,
    SUM(CASE WHEN f.work_model = 'On-Site' THEN 1 ELSE 0 END) AS onsite_count,

    -- Risk distribution
    SUM(CASE WHEN
        (CASE WHEN f.over_time = 'Yes' THEN 20 ELSE 0 END) +
        (CASE WHEN f.job_satisfaction = 1 THEN 20 WHEN f.job_satisfaction = 2 THEN 10 ELSE 0 END) +
        (CASE WHEN f.work_life_balance = 1 THEN 15 WHEN f.work_life_balance = 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.career_growth_perception <= 2 THEN 15 ELSE 0 END) +
        (CASE WHEN f.compensation_satisfaction <= 2 THEN 12 ELSE 0 END) +
        (CASE WHEN f.manager_support_score < 3.0 THEN 10 ELSE 0 END) >= 60
        THEN 1 ELSE 0 END) AS critical_risk_count,
    SUM(CASE WHEN
        (CASE WHEN f.over_time = 'Yes' THEN 20 ELSE 0 END) +
        (CASE WHEN f.job_satisfaction = 1 THEN 20 WHEN f.job_satisfaction = 2 THEN 10 ELSE 0 END) +
        (CASE WHEN f.work_life_balance = 1 THEN 15 WHEN f.work_life_balance = 2 THEN 8 ELSE 0 END) +
        (CASE WHEN f.career_growth_perception <= 2 THEN 15 ELSE 0 END) +
        (CASE WHEN f.compensation_satisfaction <= 2 THEN 12 ELSE 0 END) +
        (CASE WHEN f.manager_support_score < 3.0 THEN 10 ELSE 0 END) BETWEEN 40 AND 59
        THEN 1 ELSE 0 END) AS high_risk_count,

    -- Financial impact
    SUM(CASE WHEN f.attrition = 'Yes' THEN f.monthly_income * 6 ELSE 0 END) AS total_estimated_attrition_cost,

    -- Composite health index (0-100 scale, weighted average of normalized factors)
    ROUND(
        (
            (AVG(f.job_satisfaction) / 4.0 * 20) +          -- 20% weight
            (AVG(f.work_life_balance) / 4.0 * 20) +         -- 20% weight
            (AVG(f.career_growth_perception) / 5.0 * 15) +  -- 15% weight (1-5 scale)
            (AVG(f.manager_support_score) / 5.0 * 15) +     -- 15% weight (1-5 scale)
            (AVG(f.compensation_satisfaction) / 5.0 * 15) +  -- 15% weight (1-5 scale)
            ((1 - SUM(CASE WHEN f.attrition = 'Yes' THEN 1 ELSE 0 END) * 1.0 / COUNT(*)) * 15)  -- 15% weight
        ), 1
    ) AS workforce_health_index
FROM fact_employee f;
