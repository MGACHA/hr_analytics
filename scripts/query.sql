-- =============================================
-- HR Analytics SQL Queries
-- =============================================

-- 1) View first 10 employees
SELECT *
FROM employees

-- 2) Employees in a specific department
SELECT e.employee_id, e.first_name, e.last_name, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id
WHERE d.department_name = 'Engineering';

-- 3) Count employees by department
SELECT d.department_name, COUNT(*) AS employee_count
FROM employees e
JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- 4) Average base salary by department
SELECT d.department_name, CAST(ROUND(AVG(s.base_salary), 2) AS DECIMAL (12,2)) AS avg_salary
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN salary_history s ON s.employee_id = e.employee_id
WHERE s.effective_date = ( --latest salary
    SELECT MAX(s2.effective_date)
    FROM salary_history s2
    WHERE s2.employee_id = e.employee_id
)
GROUP BY d.department_name
ORDER BY avg_salary DESC;

-- 5) Top 10 highest paid employees (latest salary)
SELECT TOP 10 e.employee_id,
       --e.first_name +' '+ e.last_name AS full_name,
	   CONCAT (e.first_name, ' ',e.last_name) as full_name,
       d.department_name,
       s.base_salary,
       s.bonus_pct
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN salary_history s ON s.employee_id = e.employee_id
WHERE s.effective_date = ( --latest salary
    SELECT MAX(s2.effective_date)
    FROM salary_history s2
    WHERE s2.employee_id = e.employee_id
)
ORDER BY s.base_salary DESC

-- 6) Employees hired in the last 3 years
SELECT employee_id, first_name, last_name, hire_date
FROM employees
WHERE hire_date >= DATEADD(YEAR, -3, CAST(GETDATE() AS DATE)) --CAST(... AS DATE) removes time part (optional but recommended)
--WHERE hire_date >= DATEADD(YEAR, -3, GETDATE()) --GETDATE() current date & time
ORDER BY hire_date DESC;

-- 7) CTE: average salary by region
WITH latest_salary AS ( --creates a temporary result set called latest_salary
    SELECT s.employee_id, s.base_salary
    FROM salary_history s
    WHERE s.effective_date = (
        SELECT MAX(s2.effective_date) --most recent date
        FROM salary_history s2
        WHERE s2.employee_id = s.employee_id
    )
)
SELECT d.region, --aggregated results per region.
       --ROUND(AVG(ls.base_salary), 2) AS avg_salary, -- result eg.10819.190000
	   CAST(ROUND(AVG(ls.base_salary), 2) AS DECIMAL(12,2)) AS avg_salary, -- forcing 2 decimal places
       COUNT(*) AS employee_count
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN latest_salary ls ON ls.employee_id = e.employee_id
GROUP BY d.region
ORDER BY avg_salary DESC;

-- 8) Window function: salary rank within each department
WITH latest_salary AS (
    SELECT s.employee_id, s.base_salary
    FROM salary_history s 
    WHERE s.effective_date = (
        SELECT MAX(s2.effective_date) --For each employee, get their most recent salary.
        FROM salary_history s2
        WHERE s2.employee_id = s.employee_id
    )
)
SELECT d.department_name,
       e.employee_id,
      -- e.first_name +' '+ e.last_name AS full_name,
	   CONCAT (e.first_name, ' ',e.last_name) as full_name,
       ls.base_salary,
       RANK() OVER (
	   PARTITION BY d.department_name --Employees are grouped by department
	   ORDER BY ls.base_salary DESC) AS dept_salary_rank --Highest salary gets rank 1
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN latest_salary ls ON ls.employee_id = e.employee_id
ORDER BY d.department_name, dept_salary_rank;


-- 9) View all leavers with department details
SELECT l.leaver_id,
       l.employee_id,
       CONCAT(l.first_name, ' ', l.last_name) AS full_name,
       d.department_name,
       l.job_title,
       l.last_working_date,
       l.reason_for_leaving,
       l.rehire_eligible
FROM leavers l
JOIN departments d ON d.department_id = l.department_id
ORDER BY l.last_working_date DESC;


-- 10) Count leavers by leaving reason
SELECT l.reason_for_leaving,
       COUNT(*) AS leaver_count
FROM leavers l
GROUP BY l.reason_for_leaving
ORDER BY leaver_count DESC, l.reason_for_leaving;

-- 11) Count leavers by department
SELECT d.department_name,
       COUNT(*) AS leaver_count
FROM leavers l
JOIN departments d ON d.department_id = l.department_id
GROUP BY d.department_name
ORDER BY leaver_count DESC, d.department_name;


-- 12) Leavers with severance offered
SELECT l.leaver_id,
       CONCAT(l.first_name, ' ', l.last_name) AS full_name,
       l.reason_for_leaving,
       l.severance_offered,
       l.exit_interview_date
FROM leavers l
WHERE l.severance_offered IS NOT NULL
ORDER BY l.severance_offered DESC;

-- 13) Leavers in the last 6 months
SELECT l.leaver_id,
       CONCAT(l.first_name, ' ', l.last_name) AS full_name,
       l.last_working_date,
       l.reason_for_leaving
FROM leavers l
WHERE l.last_working_date >= DATEADD(MONTH, -6, CAST(GETDATE() AS DATE))
ORDER BY l.last_working_date DESC;

-- 14) Average severance by reason for leaving
SELECT l.reason_for_leaving,
       CAST(ROUND(AVG(l.severance_offered), 2) AS DECIMAL(12,2)) AS avg_severance
FROM leavers l
WHERE l.severance_offered IS NOT NULL
GROUP BY l.reason_for_leaving
ORDER BY avg_severance DESC;

-- 15) Compare active employees vs leavers by department
SELECT d.department_name,
       COUNT(DISTINCT e.employee_id) AS active_employees,
       COUNT(DISTINCT l.leaver_id) AS leavers
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id
LEFT JOIN leavers l ON l.department_id = d.department_id
GROUP BY d.department_name
ORDER BY d.department_name;

-- 16) Window function: rank leavers by severance within each department
SELECT d.department_name,
       CONCAT(l.first_name, ' ', l.last_name) AS full_name,
       l.severance_offered,
       RANK() OVER (
           PARTITION BY d.department_name
           ORDER BY l.severance_offered DESC
       ) AS severance_rank
FROM leavers l
JOIN departments d ON d.department_id = l.department_id
WHERE l.severance_offered IS NOT NULL
ORDER BY d.department_name, severance_rank;

-- 17) Length of service for leavers (years)
SELECT l.leaver_id,
       l.employee_id,
       CONCAT(l.first_name, ' ', l.last_name) AS full_name,
       e.hire_date,
       l.last_working_date,
       DATEDIFF(YEAR, e.hire_date, l.last_working_date)
       - CASE
             WHEN DATEADD(YEAR, DATEDIFF(YEAR, e.hire_date, l.last_working_date), e.hire_date) > l.last_working_date
             THEN 1
             ELSE 0
         END AS length_of_service_years,
       DATEDIFF(MONTH, e.hire_date, l.last_working_date) AS length_of_service_months,
       l.reason_for_leaving
FROM leavers l
JOIN employees e ON e.employee_id = l.employee_id
ORDER BY length_of_service_years DESC, l.last_working_date DESC;

-- 18) Average length of service for leavers by department
SELECT d.department_name,
       CAST(AVG(CAST(DATEDIFF(DAY, e.hire_date, l.last_working_date) AS DECIMAL(12,2))) / 365.25 AS DECIMAL(12,2)) AS avg_service_years,
       COUNT(*) AS leaver_count
FROM leavers l
JOIN employees e ON e.employee_id = l.employee_id
JOIN departments d ON d.department_id = l.department_id
GROUP BY d.department_name
ORDER BY avg_service_years DESC;

-- 19) Current employees with length of service (years)
SELECT e.employee_id,
       CONCAT(e.first_name, ' ', e.last_name) AS full_name,
       d.department_name,
       e.hire_date,
       DATEDIFF(YEAR, e.hire_date, CAST(GETDATE() AS DATE))
       - CASE
             WHEN DATEADD(YEAR, DATEDIFF(YEAR, e.hire_date, CAST(GETDATE() AS DATE)), e.hire_date) > CAST(GETDATE() AS DATE)
             THEN 1
             ELSE 0
         END AS length_of_service_years
FROM employees e
JOIN departments d ON d.department_id = e.department_id
ORDER BY length_of_service_years DESC, e.hire_date;
