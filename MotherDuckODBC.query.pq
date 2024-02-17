// Use this file to write queries to test your data connector
let
    // Database = "C:\Users\guen_\work\MotherDuck\dbs\test.db",
    Database = "md:my_db",
    MotherDuckToken = "",
    OdbcDatasource = MotherDuckODBC.Contents(Database, MotherDuckToken)
in
    OdbcDatasource
