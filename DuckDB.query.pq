// Use this file to write queries to test your data connector
let
    options = [read_only=1, custom_user_agent="vscode"],
    Database = "~\source\repos\DuckDBPowerQueryConnector\test\test.db",
    OdbcDatasource = DuckDB.Contents(Database, "", options)
    // Database = "md:",
    // MotherDuckToken = "",
    // OdbcDatasource = DuckDB.Contents(Database, MotherDuckToken, options)
in
    OdbcDatasource{[Item="test"]}[Data]
