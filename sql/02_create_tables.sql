-- ============================================================================
-- FILE: 02_create_tables.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Create star-schema tables with proper types, keys, and indexes
-- SCHEMA:  Star-schema-lite
--          - dim_department (department dimension)
--          - dim_job_role (job role dimension, linked to department)
--          - fact_employee (central fact table with measures and FK references)
-- ============================================================================

USE employee_analytics;

-- ============================================================================
-- DIMENSION: dim_department
-- Stores distinct departments within the organization
-- ============================================================================

DROP TABLE IF EXISTS fact_employee;
DROP TABLE IF EXISTS dim_job_role;
DROP TABLE IF EXISTS dim_department;

CREATE TABLE dim_department (
    department_id   INT             NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(50)     NOT NULL,
    PRIMARY KEY (department_id),
    UNIQUE KEY uq_department_name (department_name)
) ENGINE=InnoDB;

-- ============================================================================
-- DIMENSION: dim_job_role
-- Stores job roles with a foreign key linking each role to its department
-- ============================================================================

CREATE TABLE dim_job_role (
    role_id         INT             NOT NULL AUTO_INCREMENT,
    role_name       VARCHAR(60)     NOT NULL,
    department_id   INT             NOT NULL,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_role_name (role_name),
    KEY idx_role_department (department_id),
    CONSTRAINT fk_role_department
        FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================================
-- FACT TABLE: fact_employee
-- Central table containing all employee measures, satisfaction scores,
-- work patterns, and foreign keys to dimension tables
-- ============================================================================

CREATE TABLE fact_employee (
    employee_id                 INT             NOT NULL,
    age                         TINYINT UNSIGNED NOT NULL,
    attrition                   ENUM('Yes','No') NOT NULL,
    business_travel             ENUM('Non-Travel','Travel_Rarely','Travel_Frequently') NOT NULL,
    daily_rate                  SMALLINT UNSIGNED NOT NULL,
    distance_from_home          TINYINT UNSIGNED NOT NULL,
    education                   TINYINT UNSIGNED NOT NULL COMMENT '1=Below College, 2=College, 3=Bachelor, 4=Master, 5=Doctor',
    education_field             VARCHAR(40)     NOT NULL,
    environment_satisfaction    TINYINT UNSIGNED NOT NULL COMMENT '1=Low, 2=Medium, 3=High, 4=Very High',
    gender                      ENUM('Male','Female') NOT NULL,
    hourly_rate                 SMALLINT UNSIGNED NOT NULL,
    job_involvement             TINYINT UNSIGNED NOT NULL COMMENT '1=Low, 2=Medium, 3=High, 4=Very High',
    job_level                   TINYINT UNSIGNED NOT NULL,
    job_satisfaction            TINYINT UNSIGNED NOT NULL COMMENT '1=Low, 2=Medium, 3=High, 4=Very High',
    marital_status              ENUM('Single','Married','Divorced') NOT NULL,
    monthly_income              INT UNSIGNED    NOT NULL,
    monthly_rate                INT UNSIGNED    NOT NULL,
    num_companies_worked        TINYINT UNSIGNED NOT NULL,
    over_time                   ENUM('Yes','No') NOT NULL,
    percent_salary_hike         TINYINT UNSIGNED NOT NULL,
    performance_rating          TINYINT UNSIGNED NOT NULL COMMENT '1=Low, 2=Good, 3=Excellent, 4=Outstanding',
    relationship_satisfaction   TINYINT UNSIGNED NOT NULL COMMENT '1=Low, 2=Medium, 3=High, 4=Very High',
    stock_option_level          TINYINT UNSIGNED NOT NULL,
    total_working_years         TINYINT UNSIGNED NOT NULL,
    training_times_last_year    TINYINT UNSIGNED NOT NULL,
    work_life_balance           TINYINT UNSIGNED NOT NULL COMMENT '1=Bad, 2=Good, 3=Better, 4=Best',
    years_at_company            TINYINT UNSIGNED NOT NULL,
    years_in_current_role       TINYINT UNSIGNED NOT NULL,
    years_since_last_promotion  TINYINT UNSIGNED NOT NULL,
    years_with_curr_manager     TINYINT UNSIGNED NOT NULL,
    workload_score              DECIMAL(4,2)    NOT NULL,
    weekly_hours_worked         TINYINT UNSIGNED NOT NULL,
    monthly_meetings            TINYINT UNSIGNED NOT NULL,
    compensation_satisfaction   TINYINT UNSIGNED NOT NULL COMMENT '1=Very Low, 2=Low, 3=Moderate, 4=High, 5=Very High',
    career_growth_perception    TINYINT UNSIGNED NOT NULL COMMENT '1=No Growth, 2=Limited, 3=Moderate, 4=Good, 5=Excellent',
    manager_support_score       TINYINT UNSIGNED NOT NULL COMMENT '1=Very Poor, 2=Poor, 3=Average, 4=Good, 5=Excellent',
    work_model                  ENUM('Remote','Hybrid','Onsite') NOT NULL,
    productivity_score          TINYINT UNSIGNED NOT NULL COMMENT '1=Very Low, 2=Low, 3=Average, 4=High, 5=Very High',
    salary_band                 VARCHAR(20)     NOT NULL,
    experience_band             VARCHAR(20)     NOT NULL,
    tenure_band                 VARCHAR(20)     NOT NULL,

    -- Foreign keys to dimensions
    department_id               INT             NOT NULL,
    role_id                     INT             NOT NULL,

    -- Primary key
    PRIMARY KEY (employee_id),

    -- Foreign key constraints
    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id) REFERENCES dim_department(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_employee_role
        FOREIGN KEY (role_id) REFERENCES dim_job_role(role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Indexes for common analytical queries
    KEY idx_attrition (attrition),
    KEY idx_department (department_id),
    KEY idx_role (role_id),
    KEY idx_overtime (over_time),
    KEY idx_job_level (job_level),
    KEY idx_work_model (work_model),
    KEY idx_salary_band (salary_band),
    KEY idx_tenure_band (tenure_band),
    KEY idx_experience_band (experience_band),

    -- Composite indexes for frequent filter combinations
    KEY idx_dept_attrition (department_id, attrition),
    KEY idx_role_overtime (role_id, over_time),
    KEY idx_satisfaction_composite (job_satisfaction, environment_satisfaction, work_life_balance)
) ENGINE=InnoDB;

SELECT 'All tables created successfully.' AS status;
