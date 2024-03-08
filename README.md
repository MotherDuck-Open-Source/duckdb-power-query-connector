# DuckDB Power Query Connector by MotherDuck (Beta)

This is the Power Query Custom Connector for DuckDB. Use this to connect to a DuckDB database in memory, from a local file or on MotherDuck with Power BI and Excel.

## Installing (Beta version)

1. Install the [DuckDB v0.10.0](https://github.com/duckdb/duckdb/releases/tag/v0.10.0) ODBC driver for your platform:
      - [duckdb_odbc-linux-aarch64.zip](https://github.com/duckdb/duckdb/releases/download/v0.10.0/duckdb_odbc-linux-aarch64.zip)
      - [duckdb_odbc-linux-amd64.zip](https://github.com/duckdb/duckdb/releases/download/v0.10.0/duckdb_odbc-linux-amd64.zip)
1. Create this folder if it does not yet exist: `[Documents]\Power BI Desktop\Custom Connectors`
1. Open Power BI, go to File -> Options and settings -> Options -> Security -> Data Extensions. Enable "Allow any extensions to load without validation or warning".
![Dialog window showing Power BI Options -> Security -> Data Extensions](images/power_bi_options.png)
1. Download and copy the latest `.mez` file from [GitHub Releases](https://github.com/MotherDuck-Open-Source/DuckDBPowerQueryConnector/releases) into this folder.
