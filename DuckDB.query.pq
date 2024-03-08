// Use this file to write queries to test your data connector
let
    Database = "~\source\repos\DuckDBPowerQueryConnector\test\test.db",
    OdbcDatasource = DuckDB.Contents(Database)
    // Database = "md:my_db",
    // MotherDuckToken = "",
    // OdbcDatasource = DuckDB.Contents(Database, MotherDuckToken)
in
    OdbcDatasource{[Item="test"]}[Data]
