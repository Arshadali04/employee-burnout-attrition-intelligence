-- ============================================================================
-- FILE: 01_create_database.sql
-- PROJECT: Employee Burnout & Attrition Intelligence
-- PURPOSE: Create and initialize the employee_analytics database
-- ============================================================================

-- Drop database if it exists (use with caution in production)
DROP DATABASE IF EXISTS employee_analytics;

-- Create the analytics database with UTF-8 support
CREATE DATABASE employee_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Switch context to the new database
USE employee_analytics;

-- Confirm database is active
SELECT 'Database employee_analytics created successfully.' AS status;
