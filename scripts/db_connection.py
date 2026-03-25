import os

import pyodbc

DEFAULT_DRIVER = "ODBC Driver 18 for SQL Server"
DEFAULT_SERVER = "localhost"
DEFAULT_DATABASE = "hr_analytics"
DEFAULT_ENCRYPT = "no"
DEFAULT_TRUST_CERT = "yes"


def _base_connection_parts(database: str) -> list[str]:
    driver = os.getenv("MSSQL_DRIVER", DEFAULT_DRIVER)
    server = os.getenv("MSSQL_SERVER", DEFAULT_SERVER)
    encrypt = os.getenv("MSSQL_ENCRYPT", DEFAULT_ENCRYPT)
    trust_cert = os.getenv("MSSQL_TRUST_SERVER_CERTIFICATE", DEFAULT_TRUST_CERT)

    parts = [
        f"DRIVER={{{driver}}}",
        f"SERVER={server}",
        f"DATABASE={database}",
        f"Encrypt={encrypt}",
        f"TrustServerCertificate={trust_cert}",
    ]

    username = os.getenv("MSSQL_USERNAME")
    password = os.getenv("MSSQL_PASSWORD")
    if username and password:
        parts.append(f"UID={username}")
        parts.append(f"PWD={password}")
    else:
        parts.append("Trusted_Connection=yes")

    return parts


def build_connection_string(database: str) -> str:
    return ";".join(_base_connection_parts(database))


def get_target_database() -> str:
    return os.getenv("MSSQL_DATABASE", DEFAULT_DATABASE)


def connect_to_database(database: str | None = None) -> pyodbc.Connection:
    target = database or get_target_database()
    return pyodbc.connect(build_connection_string(target))


def ensure_database_exists(database: str) -> None:
    with connect_to_database("master") as master_conn:
        cursor = master_conn.cursor()
        cursor.execute(
            """
            IF DB_ID(?) IS NULL
            BEGIN
                DECLARE @sql NVARCHAR(MAX) = N'CREATE DATABASE [' + REPLACE(?, ']', ']]') + N']';
                EXEC(@sql);
            END
            """,
            database,
            database,
        )
        master_conn.commit()
