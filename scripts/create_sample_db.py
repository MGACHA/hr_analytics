import random
from datetime import date, timedelta
from pathlib import Path

from db_connection import connect_to_database, ensure_database_exists, get_target_database

BASE_DIR = Path(__file__).resolve().parents[1]

random.seed(42)


def random_date(start: date, end: date) -> date:
    days = (end - start).days
    return start + timedelta(days=random.randint(0, days))


def create_schema(conn) -> None:
    cursor = conn.cursor()

    statements = [
        "DROP TABLE IF EXISTS time_off_requests",
        "DROP TABLE IF EXISTS benefits",
        "DROP TABLE IF EXISTS salary_history",
        "DROP TABLE IF EXISTS employees",
        "DROP TABLE IF EXISTS departments",
        """
        CREATE TABLE departments (
            department_id INT PRIMARY KEY,
            department_name NVARCHAR(100) NOT NULL UNIQUE,
            region NVARCHAR(50) NOT NULL
        )
        """,
        """
        CREATE TABLE employees (
            employee_id INT PRIMARY KEY,
            first_name NVARCHAR(80) NOT NULL,
            last_name NVARCHAR(80) NOT NULL,
            gender NVARCHAR(10) NOT NULL,
            birth_date DATE NOT NULL,
            hire_date DATE NOT NULL,
            department_id INT NOT NULL,
            job_title NVARCHAR(120) NOT NULL,
            email NVARCHAR(255) NULL,
            CONSTRAINT FK_employees_departments
                FOREIGN KEY (department_id) REFERENCES departments(department_id)
        )
        """,
        """
        CREATE TABLE salary_history (
            salary_id INT PRIMARY KEY,
            employee_id INT NOT NULL,
            effective_date DATE NOT NULL,
            base_salary DECIMAL(12, 2) NOT NULL,
            bonus_pct DECIMAL(5, 2) NOT NULL,
            currency NVARCHAR(10) NOT NULL DEFAULT 'USD',
            CONSTRAINT FK_salary_history_employees
                FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        )
        """,
        """
        CREATE TABLE benefits (
            benefit_id INT PRIMARY KEY,
            employee_id INT NOT NULL,
            health_plan NVARCHAR(50) NOT NULL,
            retirement_pct DECIMAL(5, 2) NOT NULL,
            pto_days INT NOT NULL,
            remote_allowance DECIMAL(10, 2) NOT NULL,
            CONSTRAINT FK_benefits_employees
                FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        )
        """,
        """
        CREATE TABLE time_off_requests (
            request_id INT PRIMARY KEY,
            employee_id INT NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE NOT NULL,
            status NVARCHAR(30) NOT NULL,
            reason NVARCHAR(50) NOT NULL,
            CONSTRAINT FK_time_off_requests_employees
                FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        )
        """,
    ]

    for statement in statements:
        cursor.execute(statement)


def insert_departments(conn) -> None:
    rows = [
        (1, "Engineering", "North"),
        (2, "Finance", "North"),
        (3, "Human Resources", "Central"),
        (4, "Sales", "South"),
        (5, "Marketing", "East"),
        (6, "Operations", "West"),
    ]
    conn.cursor().executemany(
        "INSERT INTO departments (department_id, department_name, region) VALUES (?, ?, ?)",
        rows,
    )


def insert_employees(conn, total: int = 120) -> None:
    first_names = [
        "Ava", "Liam", "Noah", "Emma", "Olivia", "Mason", "Sophia", "Lucas", "Mia", "Ethan",
        "Isabella", "James", "Amelia", "Elijah", "Harper", "Benjamin", "Ella", "Henry", "Aria", "Jack",
    ]
    last_names = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia", "Martinez", "Lee",
        "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Clark", "Lewis", "Walker",
    ]
    job_titles = {
        1: ["Software Engineer", "Senior Engineer", "Data Engineer", "QA Engineer"],
        2: ["Financial Analyst", "Senior Accountant", "Controller"],
        3: ["HR Generalist", "Talent Specialist", "HR Manager"],
        4: ["Sales Executive", "Account Manager", "Regional Sales Lead"],
        5: ["Marketing Analyst", "Content Strategist", "Campaign Manager"],
        6: ["Operations Analyst", "Supply Planner", "Ops Manager"],
    }

    rows = []
    for employee_id in range(1, total + 1):
        first = random.choice(first_names)
        last = random.choice(last_names)
        dept_id = random.randint(1, 6)
        gender = random.choice(["F", "M"])
        birth = random_date(date(1970, 1, 1), date(2002, 12, 31)).isoformat()
        hire = random_date(date(2014, 1, 1), date(2025, 12, 1)).isoformat()
        title = random.choice(job_titles[dept_id])
        email = f"{first.lower()}.{last.lower()}.{employee_id}@example.com"

        if employee_id in {17, 58}:  # intentional quality issue (missing email)
            email = None

        rows.append((employee_id, first, last, gender, birth, hire, dept_id, title, email))

    conn.cursor().executemany(
        """
        INSERT INTO employees (
            employee_id, first_name, last_name, gender, birth_date, hire_date,
            department_id, job_title, email
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        rows,
    )


def insert_salary_history(conn) -> None:
    rows = []
    salary_id = 1

    for employee_id in range(1, 121):
        start_salary = random.randint(42000, 90000)
        current_salary = round(start_salary * random.uniform(1.1, 1.9), 2)

        if employee_id in {3, 77}:  # intentional quality issue (out-of-range)
            current_salary = 295000.0

        rows.append((salary_id, employee_id, "2023-01-01", start_salary, round(random.uniform(3, 12), 2), "USD"))
        salary_id += 1
        rows.append((salary_id, employee_id, "2024-01-01", round((start_salary + current_salary) / 2, 2), round(random.uniform(3, 12), 2), "USD"))
        salary_id += 1
        rows.append((salary_id, employee_id, "2025-01-01", current_salary, round(random.uniform(3, 12), 2), "USD"))
        salary_id += 1

    conn.cursor().executemany(
        """
        INSERT INTO salary_history (
            salary_id, employee_id, effective_date, base_salary, bonus_pct, currency
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        rows,
    )


def insert_benefits(conn) -> None:
    plans = ["Basic", "Standard", "Premium"]
    rows = []

    for employee_id in range(1, 121):
        retirement_pct = round(random.uniform(2, 10), 2)
        pto_days = random.randint(12, 28)
        remote_allowance = random.choice([0, 50, 75, 100, 150])

        if employee_id in {21}:  # intentional quality issue (invalid retirement %)
            retirement_pct = 18.5

        rows.append((employee_id, employee_id, random.choice(plans), retirement_pct, pto_days, remote_allowance))

    conn.cursor().executemany(
        """
        INSERT INTO benefits (
            benefit_id, employee_id, health_plan, retirement_pct, pto_days, remote_allowance
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        rows,
    )


def insert_time_off(conn) -> None:
    reasons = ["Vacation", "Sick", "Training", "Family", "Personal"]
    status_values = ["Approved", "Pending", "Rejected"]
    rows = []
    request_id = 1

    for employee_id in range(1, 121):
        for _ in range(random.randint(1, 4)):
            start = random_date(date(2024, 1, 1), date(2026, 2, 1))
            end = start + timedelta(days=random.randint(1, 7))
            rows.append(
                (
                    request_id,
                    employee_id,
                    start.isoformat(),
                    end.isoformat(),
                    random.choice(status_values),
                    random.choice(reasons),
                )
            )
            request_id += 1

    conn.cursor().executemany(
        """
        INSERT INTO time_off_requests (
            request_id, employee_id, start_date, end_date, status, reason
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        rows,
    )


def main() -> None:
    target_database = get_target_database()
    ensure_database_exists(target_database)

    conn = connect_to_database(target_database)
    try:
        create_schema(conn)
        insert_departments(conn)
        insert_employees(conn)
        insert_salary_history(conn)
        insert_benefits(conn)
        insert_time_off(conn)
        conn.commit()
    finally:
        conn.close()

    print(f"Database created successfully in SQL Server database: {target_database}")


if __name__ == "__main__":
    main()
