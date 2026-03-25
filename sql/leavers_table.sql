-- SQL Script: Create LEAVERS table and insert sample data

-- DROP TABLE IF EXISTS leavers;

CREATE TABLE leavers (
    leaver_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    department_id INT NOT NULL,
    first_name NVARCHAR(80) NOT NULL,
    last_name NVARCHAR(80) NOT NULL,
    job_title NVARCHAR(120) NOT NULL,
    last_working_date DATE NOT NULL,
    reason_for_leaving NVARCHAR(100) NOT NULL,
    severance_offered DECIMAL(12, 2) NULL,
    rehire_eligible BIT NOT NULL DEFAULT 1,
    exit_interview_date DATE NULL,
    CONSTRAINT FK_leavers_employees
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT FK_leavers_departments
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- Insert sample leaver data
INSERT INTO leavers (
    leaver_id, employee_id, department_id, first_name, last_name, job_title,
    last_working_date, reason_for_leaving, severance_offered, rehire_eligible, exit_interview_date
) VALUES
(1, 5, 1, 'Michael', 'Chen', 'Senior Engineer', '2024-06-30', 'Career Change', 25000.00, 1, '2024-06-28'),
(2, 12, 2, 'Sarah', 'Johnson', 'Financial Analyst', '2024-08-15', 'Relocation', 15000.00, 1, '2024-08-14'),
(3, 28, 3, 'David', 'Walker', 'HR Generalist', '2024-09-30', 'Retirement', 35000.00, 0, '2024-09-27'),
(4, 45, 4, 'Lisa', 'Martinez', 'Sales Executive', '2024-07-31', 'Competing Offer', 20000.00, 0, '2024-07-30'),
(5, 67, 5, 'James', 'Anderson', 'Content Strategist', '2024-10-15', 'Health Reasons', NULL, 1, NULL),
(6, 89, 6, 'Emma', 'Williams', 'Operations Analyst', '2024-11-30', 'Further Education', 10000.00, 1, '2024-11-29'),
(7, 101, 1, 'Robert', 'Brown', 'QA Engineer', '2024-12-20', 'Better Opportunity', 18000.00, 1, '2024-12-19');

-- Verify the data
SELECT COUNT(*) AS Total_Leavers FROM leavers;
SELECT * FROM leavers ORDER BY leaver_id;
