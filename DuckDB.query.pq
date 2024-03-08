// Use this file to write queries to test your data connector
let
    Database = "C:\Users\Guen Prawiroatmodjo\source\PowerBITests\test2.db",
    OdbcDatasource = DuckDB.Contents(Database)
    // Database = "md:my_db",
    // MotherDuckToken = "",
    // OdbcDatasource = DuckDB.Contents(Database, MotherDuckToken)
in
    OdbcDatasource{[Item="test"]}[Data]
