--17) Length of service for leavers (years)
CREATE OR ALTER VIEW dbo.vw_leavers_service_length AS

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
--ORDER BY length_of_service_years DESC, l.last_working_date DESC;


-- 8) Window function: salary rank within each department

CREATE OR ALTER VIEW vw_employee_latest_salary AS 
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
--ORDER BY d.department_name, dept_salary_rank;



-- 3) Count employees by department
CREATE or ALTER VIEW vw_department_headcount AS
SELECT d.department_name, COUNT(*) AS employee_count
FROM employees e
JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_name
--ORDER BY employee_count DESC;


-- 15) Compare active employees vs leavers by department

CREATE or ALTER VIEW vw_department_leavers_summary AS
SELECT d.department_name,
       COUNT(DISTINCT e.employee_id) AS active_employees,
       COUNT(DISTINCT l.leaver_id) AS leavers
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id
LEFT JOIN leavers l ON l.department_id = d.department_id
GROUP BY d.department_name
--ORDER BY d.department_name;
