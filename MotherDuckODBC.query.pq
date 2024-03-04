// Use this file to write queries to test your data connector
let
    Database = "absolute\path\to\test.db",
    OdbcDatasource = MotherDuckODBC.Contents(Database)
    // Database = "md:my_db",
    // MotherDuckToken = "",
    // OdbcDatasource = MotherDuckODBC.Contents(Database, MotherDuckToken)
in
    OdbcDatasource{[Item="numbers"]}[Data]
