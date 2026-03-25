Create the sample database.
From the terminal in the project folder, run:

(bash)
```bash
pip install -r requirements.txt
```

Set SQL Server connection values (PowerShell example):

```powershell
$env:MSSQL_SERVER = "localhost"
$env:MSSQL_DATABASE = "hr_analytics"
```

Then run:


(bash)
```bash
python scripts/create_sample_db.py
```

This creates and seeds tables in SQL Server database `hr_analytics` (or your `MSSQL_DATABASE` value).

This Python script, scripts/create_sample_db.py will run db_connection.py - Check whether you have the correct credentials.

when ERROR:
pyodbc.InterfaceError: ('IM002', '[IM002] [Microsoft][ODBC Driver Manager] Data source name not found and no default driver specified (0) (SQLDriverConnect)')
That error means check the ODBC driver setup. IM002 means Python could not find the SQL Server ODBC driver name in your connection string. Run this in PowerShell first:

```powershell
Get-OdbcDriver | Where-Object { $_.Name -like "*SQL Server*" } | Select-Object Name
```

If you see ODBC Driver 18 for SQL Server:
```powershell
$env:MSSQL_DRIVER = "ODBC Driver 18 for SQL Server"
$env:MSSQL_SERVER = "localhost"
$env:MSSQL_DATABASE = "hr_analytics"
python scripts/create_sample_db.py
```
If you see ODBC Driver 17 for SQL Server:
```powershell
$env:MSSQL_DRIVER = "ODBC Driver 17 for SQL Server"
$env:MSSQL_SERVER = "localhost"
$env:MSSQL_DATABASE = "hr_analytics"
```
