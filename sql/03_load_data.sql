-- ============================================================================
-- FILE: 03_load_data.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Load dimension data and representative sample rows into fact table
-- NOTE:    For production, replace fact_employee INSERTs with LOAD DATA INFILE
--
-- BAND LABELS (must match generate_augmented_dataset.py output exactly):
--   SalaryBand:    Low (<3k) | Below Average (3-6k) | Average (6-10k)
--                  | Above Average (10-15k) | High (15k+)
--   ExperienceBand: Entry (0-2) | Early (3-5) | Mid (6-10)
--                   | Senior (11-20) | Expert (20+)
--   TenureBand:    New (0-1) | Settling (2-3) | Established (4-5)
--                  | Veteran (6-10) | Lifer (10+)
--   WorkModel:     Remote | Hybrid | Onsite
--   WorkloadScore, ManagerSupportScore, ProductivityScore: integers 1-5
-- ============================================================================

USE employee_analytics;

-- ============================================================================
-- SECTION 1: LOAD DIMENSION DATA
-- ============================================================================

-- --------------------------------------------------------------------------
-- dim_department: 3 departments from the dataset
-- --------------------------------------------------------------------------
INSERT INTO dim_department (department_id, department_name) VALUES
    (1, 'Human Resources'),
    (2, 'Research & Development'),
    (3, 'Sales');

-- --------------------------------------------------------------------------
-- dim_job_role: 9 roles mapped to their departments
-- NOTE: 'Manager' role appears across all departments in the full IBM dataset
--       but is mapped to Sales here for schema simplicity. Full-load scripts
--       should handle cross-department Manager assignments with custom SQL.
-- --------------------------------------------------------------------------
INSERT INTO dim_job_role (role_id, role_name, department_id) VALUES
    (1, 'Human Resources',            1),
    (2, 'Research Director',           2),
    (3, 'Research Scientist',          2),
    (4, 'Laboratory Technician',       2),
    (5, 'Manufacturing Director',      2),
    (6, 'Healthcare Representative',   2),
    (7, 'Manager',                     3),
    (8, 'Sales Executive',             3),
    (9, 'Sales Representative',        3);

-- ============================================================================
-- SECTION 2: LOAD FACT DATA (Representative Sample)
-- 20 rows covering diverse profiles: varied attrition, departments, roles,
-- overtime, satisfaction levels, tenures, and work models.
--
-- All band/score values are computed to match Python generate_augmented_dataset.py
-- logic: SalaryBand from MonthlyIncome bins, ExperienceBand from TotalWorkingYears,
-- TenureBand from YearsAtCompany, WorkloadScore/ProductivityScore as integers 1-5.
-- ============================================================================

INSERT INTO fact_employee (
    employee_id, age, attrition, business_travel, daily_rate,
    distance_from_home, education, education_field, environment_satisfaction,
    gender, hourly_rate, job_involvement, job_level, job_satisfaction,
    marital_status, monthly_income, monthly_rate, num_companies_worked,
    over_time, percent_salary_hike, performance_rating, relationship_satisfaction,
    stock_option_level, total_working_years, training_times_last_year,
    work_life_balance, years_at_company, years_in_current_role,
    years_since_last_promotion, years_with_curr_manager, workload_score,
    weekly_hours_worked, monthly_meetings, compensation_satisfaction,
    career_growth_perception, manager_support_score, work_model,
    productivity_score, salary_band, experience_band, tenure_band,
    department_id, role_id
) VALUES
-- Employee 1001: Young single male, high attrition risk — OT, low sat, early career
-- income=3200→Below Average | exp=5yrs→Early(3-5) | tenure=2yrs→Settling(2-3)
-- workload: OT+attrition push → 4; productivity: low sat, OT → 3
(1001, 28, 'Yes', 'Travel_Frequently', 1102,
 15, 3, 'Life Sciences', 1,
 'Male', 65, 3, 1, 1,
 'Single', 3200, 12500, 3,
 'Yes', 11, 3, 2,
 0, 5, 2,
 1, 2, 1,
 0, 1, 4,
 55, 12, 1,
 1, 2, 'Onsite',
 3, 'Below Average', 'Early (3-5)', 'Settling (2-3)',
 2, 4),

-- Employee 1002: Mid-career female, stable, R&D
-- income=6500→Average | exp=10yrs→Mid(6-10) | tenure=7yrs→Veteran(6-10)
-- workload: no OT, level 2 → 3; productivity: good involvement → 4
(1002, 35, 'No', 'Travel_Rarely', 850,
 5, 4, 'Medical', 4,
 'Female', 78, 4, 2, 4,
 'Married', 6500, 18200, 2,
 'No', 15, 3, 4,
 2, 10, 3,
 3, 7, 5,
 1, 6, 3,
 42, 8, 4,
 4, 4, 'Hybrid',
 4, 'Average', 'Mid (6-10)', 'Veteran (6-10)',
 2, 3),

-- Employee 1003: Senior Sales Executive, high income, no attrition
-- income=15800→High | exp=22yrs→Expert(20+) | tenure=18yrs→Lifer(10+)
-- workload: high level, travel → 4; productivity: perf=4, high involvement → 5
(1003, 45, 'No', 'Travel_Frequently', 1350,
 2, 5, 'Marketing', 3,
 'Male', 95, 4, 4, 3,
 'Married', 15800, 22000, 4,
 'No', 18, 4, 3,
 3, 22, 4,
 4, 18, 15,
 3, 12, 4,
 45, 15, 3,
 3, 4, 'Onsite',
 5, 'High', 'Expert (20+)', 'Lifer (10+)',
 3, 8),

-- Employee 1004: Young HR professional, left (attrition)
-- income=2800→Low | exp=2yrs→Entry(0-2) | tenure=1yr→New(0-1)
-- workload: OT+attrition → 4; productivity: low involvement → 3
(1004, 24, 'Yes', 'Non-Travel', 600,
 20, 2, 'Human Resources', 2,
 'Female', 45, 2, 1, 2,
 'Single', 2800, 9500, 1,
 'Yes', 12, 3, 1,
 0, 2, 1,
 2, 1, 0,
 0, 0, 4,
 52, 6, 2,
 1, 3, 'Onsite',
 3, 'Low', 'Entry (0-2)', 'New (0-1)',
 1, 1),

-- Employee 1005: Remote worker, high satisfaction, R&D
-- income=9200→Average | exp=14yrs→Senior(11-20) | tenure=10yrs→Veteran(6-10)
-- workload: no OT, level 3 → 3; productivity: average perf/involvement → 3
(1005, 38, 'No', 'Travel_Rarely', 1200,
 25, 4, 'Technical Degree', 4,
 'Male', 88, 3, 3, 4,
 'Married', 9200, 16800, 3,
 'No', 14, 3, 4,
 1, 14, 3,
 4, 10, 8,
 2, 7, 3,
 40, 6, 4,
 4, 4, 'Remote',
 3, 'Average', 'Senior (11-20)', 'Veteran (6-10)',
 2, 5),

-- Employee 1006: Overworked lab tech, burned out, left
-- income=3500→Below Average | exp=6yrs→Mid(6-10) | tenure=3yrs→Settling(2-3)
-- workload: OT+attrition, low sat → 5; productivity: low satisfaction → 3
(1006, 30, 'Yes', 'Travel_Rarely', 780,
 8, 3, 'Life Sciences', 1,
 'Female', 55, 3, 1, 1,
 'Divorced', 3500, 11000, 2,
 'Yes', 11, 3, 2,
 0, 6, 2,
 1, 3, 2,
 1, 2, 5,
 60, 14, 1,
 2, 2, 'Onsite',
 3, 'Below Average', 'Mid (6-10)', 'Settling (2-3)',
 2, 4),

-- Employee 1007: Sales Rep, travel-heavy, attrition
-- income=2900→Low | exp=4yrs→Early(3-5) | tenure=3yrs→Settling(2-3)
-- workload: OT+attrition → 4; productivity: moderate involvement → 3
(1007, 26, 'Yes', 'Travel_Frequently', 950,
 12, 3, 'Marketing', 2,
 'Male', 60, 2, 1, 2,
 'Single', 2900, 10200, 2,
 'Yes', 13, 3, 1,
 0, 4, 2,
 2, 3, 2,
 0, 2, 4,
 54, 10, 2,
 2, 2, 'Onsite',
 3, 'Low', 'Early (3-5)', 'Settling (2-3)',
 3, 9),

-- Employee 1008: Healthcare Rep, hybrid, stable
-- income=8800→Average | exp=18yrs→Senior(11-20) | tenure=12yrs→Lifer(10+)
-- workload: no OT, level 3 → 3; productivity: good involvement/perf → 3
(1008, 42, 'No', 'Travel_Rarely', 1100,
 7, 4, 'Medical', 3,
 'Female', 82, 3, 3, 3,
 'Married', 8800, 19500, 3,
 'No', 16, 3, 3,
 2, 18, 3,
 3, 12, 9,
 2, 8, 3,
 43, 9, 3,
 3, 4, 'Hybrid',
 3, 'Average', 'Senior (11-20)', 'Lifer (10+)',
 2, 6),

-- Employee 1009: Research Director, high income, tenured
-- income=19500→High | exp=30yrs→Expert(20+) | tenure=25yrs→Lifer(10+)
-- workload: high level, no OT → 4; productivity: perf=4, high involvement → 5
(1009, 52, 'No', 'Non-Travel', 1450,
 3, 5, 'Life Sciences', 4,
 'Male', 100, 4, 5, 4,
 'Married', 19500, 25000, 5,
 'No', 20, 4, 4,
 3, 30, 5,
 4, 25, 20,
 5, 18, 4,
 44, 18, 4,
 4, 5, 'Onsite',
 5, 'High', 'Expert (20+)', 'Lifer (10+)',
 2, 2),

-- Employee 1010: Mid-level Manager, Sales
-- income=13500→Above Average | exp=16yrs→Senior(11-20) | tenure=14yrs→Lifer(10+)
-- workload: no OT, level 4 → 4; productivity: decent perf/involvement → 4
(1010, 40, 'No', 'Travel_Frequently', 1250,
 10, 4, 'Marketing', 3,
 'Female', 90, 4, 4, 3,
 'Divorced', 13500, 20000, 4,
 'No', 17, 3, 3,
 2, 16, 3,
 3, 14, 12,
 4, 10, 4,
 46, 14, 3,
 3, 4, 'Onsite',
 4, 'Above Average', 'Senior (11-20)', 'Lifer (10+)',
 3, 7),

-- Employee 1011: Remote early career, attrition risk
-- income=3100→Below Average | exp=3yrs→Early(3-5) | tenure=2yrs→Settling(2-3)
-- workload: no OT but attrition risk → 3; productivity: low involvement → 3
(1011, 27, 'Yes', 'Non-Travel', 700,
 30, 3, 'Technical Degree', 2,
 'Male', 52, 2, 1, 2,
 'Single', 3100, 10800, 1,
 'No', 11, 3, 2,
 0, 3, 1,
 2, 2, 1,
 0, 1, 3,
 44, 4, 2,
 1, 3, 'Remote',
 3, 'Below Average', 'Early (3-5)', 'Settling (2-3)',
 2, 3),

-- Employee 1012: Long-tenured female HR, satisfied
-- income=10200→Above Average | exp=20yrs→Senior(11-20) | tenure=15yrs→Lifer(10+)
-- workload: no OT, level 3 → 3; productivity: average perf/involvement → 3
(1012, 48, 'No', 'Non-Travel', 900,
 4, 4, 'Human Resources', 4,
 'Female', 75, 3, 3, 4,
 'Married', 10200, 17500, 2,
 'No', 15, 3, 4,
 1, 20, 4,
 4, 15, 12,
 3, 10, 3,
 40, 7, 4,
 4, 5, 'Hybrid',
 3, 'Above Average', 'Senior (11-20)', 'Lifer (10+)',
 1, 1),

-- Employee 1013: Overworked Sales Executive, stayed despite burnout
-- income=5800→Below Average | exp=8yrs→Mid(6-10) | tenure=6yrs→Veteran(6-10)
-- workload: OT, level 2 → 4; productivity: moderate → 3
(1013, 34, 'No', 'Travel_Frequently', 1050,
 18, 3, 'Marketing', 2,
 'Male', 72, 3, 2, 2,
 'Married', 5800, 14500, 3,
 'Yes', 13, 3, 2,
 1, 8, 2,
 2, 6, 4,
 1, 4, 4,
 53, 11, 2,
 2, 3, 'Onsite',
 3, 'Below Average', 'Mid (6-10)', 'Veteran (6-10)',
 3, 8),

-- Employee 1014: Manufacturing Director, hybrid
-- income=14200→Above Average | exp=20yrs→Senior(11-20) | tenure=16yrs→Lifer(10+)
-- workload: no OT, level 4 → 4; productivity: perf=4, high involvement → 5
(1014, 44, 'No', 'Travel_Rarely', 1300,
 6, 4, 'Technical Degree', 3,
 'Female', 92, 4, 4, 3,
 'Married', 14200, 21000, 3,
 'No', 18, 4, 4,
 2, 20, 4,
 3, 16, 14,
 4, 12, 4,
 44, 12, 3,
 4, 4, 'Hybrid',
 5, 'Above Average', 'Senior (11-20)', 'Lifer (10+)',
 2, 5),

-- Employee 1015: Young researcher, low pay, at-risk
-- income=2950→Low | exp=3yrs→Early(3-5) | tenure=2yrs→Settling(2-3)
-- workload: no OT, level 1 → 3; productivity: average perf/involvement → 3
(1015, 25, 'No', 'Travel_Rarely', 680,
 9, 3, 'Life Sciences', 2,
 'Female', 48, 3, 1, 2,
 'Single', 2950, 9800, 1,
 'No', 12, 3, 2,
 0, 3, 2,
 2, 2, 1,
 0, 1, 3,
 43, 5, 2,
 2, 3, 'Onsite',
 3, 'Low', 'Early (3-5)', 'Settling (2-3)',
 2, 3),

-- Employee 1016: Experienced male, divorced, moderate satisfaction
-- income=12800→Above Average | exp=25yrs→Expert(20+) | tenure=20yrs→Lifer(10+)
-- workload: no OT, level 4 → 3; productivity: average perf/involvement → 3
(1016, 50, 'No', 'Non-Travel', 1180,
 2, 5, 'Medical', 3,
 'Male', 85, 3, 4, 3,
 'Divorced', 12800, 19000, 6,
 'No', 14, 3, 3,
 1, 25, 3,
 3, 20, 16,
 6, 14, 3,
 42, 10, 3,
 3, 3, 'Onsite',
 3, 'Above Average', 'Expert (20+)', 'Lifer (10+)',
 2, 6),

-- Employee 1017: Lab Tech, young, remote, engaged
-- income=4200→Below Average | exp=5yrs→Early(3-5) | tenure=4yrs→Established(4-5)
-- workload: no OT, level 2 → 3; productivity: average perf/involvement → 3
(1017, 29, 'No', 'Non-Travel', 820,
 22, 3, 'Life Sciences', 3,
 'Male', 58, 3, 2, 3,
 'Single', 4200, 12000, 1,
 'No', 13, 3, 3,
 1, 5, 3,
 3, 4, 3,
 1, 3, 3,
 41, 6, 3,
 3, 4, 'Remote',
 3, 'Below Average', 'Early (3-5)', 'Established (4-5)',
 2, 4),

-- Employee 1018: Sales Rep, early attrition
-- income=2600→Low | exp=1yr→Entry(0-2) | tenure=1yr→New(0-1)
-- workload: OT+attrition, level 1 → 4; productivity: low involvement → 3
(1018, 23, 'Yes', 'Travel_Frequently', 550,
 25, 2, 'Marketing', 1,
 'Female', 42, 2, 1, 1,
 'Single', 2600, 8500, 1,
 'Yes', 11, 3, 1,
 0, 1, 1,
 1, 1, 0,
 0, 0, 4,
 58, 8, 1,
 1, 2, 'Onsite',
 3, 'Low', 'Entry (0-2)', 'New (0-1)',
 3, 9),

-- Employee 1019: Mid-career female, hybrid R&D, good balance
-- income=8500→Average | exp=12yrs→Senior(11-20) | tenure=9yrs→Veteran(6-10)
-- workload: no OT, level 3 → 3; productivity: good involvement → 4
(1019, 36, 'No', 'Travel_Rarely', 980,
 11, 4, 'Life Sciences', 4,
 'Female', 76, 4, 3, 4,
 'Married', 8500, 17000, 2,
 'No', 16, 3, 4,
 2, 12, 3,
 4, 9, 7,
 2, 6, 3,
 41, 7, 4,
 4, 4, 'Hybrid',
 4, 'Average', 'Senior (11-20)', 'Veteran (6-10)',
 2, 3),

-- Employee 1020: Senior HR Manager, considering exit
-- income=11000→Above Average | exp=22yrs→Expert(20+) | tenure=15yrs→Lifer(10+)
-- workload: no OT but attrition, level 3 → 3; productivity: moderate → 3
(1020, 46, 'Yes', 'Travel_Rarely', 1050,
 14, 4, 'Human Resources', 2,
 'Male', 80, 3, 3, 2,
 'Married', 11000, 18000, 5,
 'No', 12, 3, 2,
 1, 22, 2,
 2, 15, 10,
 7, 8, 3,
 45, 9, 2,
 2, 3, 'Onsite',
 3, 'Above Average', 'Expert (20+)', 'Lifer (10+)',
 1, 1);

-- ============================================================================
-- SECTION 3: PRODUCTION LOAD ALTERNATIVE (commented out)
-- For bulk loading the full 1470-row dataset from CSV
-- ============================================================================

/*
LOAD DATA INFILE '/var/lib/mysql-files/employee_burnout_data.csv'
INTO TABLE fact_employee
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(employee_id, age, attrition, business_travel, daily_rate,
 distance_from_home, education, education_field, environment_satisfaction,
 gender, hourly_rate, job_involvement, job_level, job_satisfaction,
 marital_status, monthly_income, monthly_rate, num_companies_worked,
 over_time, percent_salary_hike, performance_rating, relationship_satisfaction,
 stock_option_level, total_working_years, training_times_last_year,
 work_life_balance, years_at_company, years_in_current_role,
 years_since_last_promotion, years_with_curr_manager, workload_score,
 weekly_hours_worked, monthly_meetings, compensation_satisfaction,
 career_growth_perception, manager_support_score, work_model,
 productivity_score, salary_band, experience_band, tenure_band,
 @department_name, @role_name)
SET
 department_id = (SELECT department_id FROM dim_department WHERE department_name = @department_name),
 role_id = (SELECT role_id FROM dim_job_role WHERE role_name = @role_name);
*/

-- Verify load counts
SELECT 'Dimension load summary:' AS section;
SELECT 'dim_department' AS table_name, COUNT(*) AS row_count FROM dim_department
UNION ALL
SELECT 'dim_job_role', COUNT(*) FROM dim_job_role
UNION ALL
SELECT 'fact_employee', COUNT(*) FROM fact_employee;
