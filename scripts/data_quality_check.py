import csv
from pathlib import Path

from db_connection import connect_to_database, get_target_database

BASE_DIR = Path(__file__).resolve().parents[1]
OUTPUT_DIR = BASE_DIR / "output"
REPORT_PATH = OUTPUT_DIR / "data_quality_report.csv"


def run_scalar(conn, query: str) -> int:
    cursor = conn.cursor()
    cursor.execute(query)
    row = cursor.fetchone()
    return int(row[0]) if row else 0


def collect_quality_metrics(conn) -> list[tuple[str, int, str]]:
    checks = [
        (
            "missing_email",
            """
            SELECT COUNT(*)
            FROM employees
            WHERE email IS NULL OR TRIM(email) = ''
            """,
            "Should be 0"
        ),
        (
            "duplicate_email",
            """
            SELECT COUNT(*)
            FROM (
                SELECT email
                FROM employees
                WHERE email IS NOT NULL
                GROUP BY email
                HAVING COUNT(*) > 1
            ) t
            """,
            "Should be 0"
        ),
        (
            "salary_outside_expected_range",
            """
            SELECT COUNT(*)
            FROM salary_history s
            WHERE s.effective_date = (
                SELECT MAX(s2.effective_date)
                FROM salary_history s2
                WHERE s2.employee_id = s.employee_id
            )
            AND (s.base_salary < 30000 OR s.base_salary > 250000)
            """,
            "Expected range: 30000 to 250000"
        ),
        (
            "future_hire_date",
            """
            SELECT COUNT(*)
            FROM employees
            WHERE hire_date > CAST(GETDATE() AS DATE)
            """,
            "Should be 0"
        ),
        (
            "invalid_retirement_pct",
            """
            SELECT COUNT(*)
            FROM benefits
            WHERE retirement_pct < 0 OR retirement_pct > 15
            """,
            "Expected range: 0 to 15"
        ),
        (
            "invalid_pto_days",
            """
            SELECT COUNT(*)
            FROM benefits
            WHERE pto_days < 0 OR pto_days > 40
            """,
            "Expected range: 0 to 40"
        ),
    ]

    results = []
    for check_name, query, expectation in checks:
        issue_count = run_scalar(conn, query)
        results.append((check_name, issue_count, expectation))

    return results


def write_report(results: list[tuple[str, int, str]]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with REPORT_PATH.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(["check_name", "issue_count", "expectation", "status"])

        for check_name, issue_count, expectation in results:
            status = "PASS" if issue_count == 0 else "FAIL"
            writer.writerow([check_name, issue_count, expectation, status])


def main() -> None:
    target_database = get_target_database()
    conn = connect_to_database(target_database)
    try:
        results = collect_quality_metrics(conn)
    finally:
        conn.close()

    write_report(results)

    failing = [r for r in results if r[1] > 0]
    print(f"Quality report saved: {REPORT_PATH}")
    print(f"Source SQL Server database: {target_database}")
    print(f"Total checks: {len(results)} | Failing checks: {len(failing)}")


if __name__ == "__main__":
    main()
