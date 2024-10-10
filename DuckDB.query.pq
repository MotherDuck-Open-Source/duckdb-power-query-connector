// Use this file to write queries to test your data connector
let
    options = [custom_user_agent="vscode"],
    Database = "~\test.db",
    // Uncomment line below to connect to MotherDuck
    // Database = "md:",
    // To get your MotherDuck token, go to https://app.motherduck.com/token-request?appName=PowerQuerySDK
    MotherDuckToken = "",
    // ReadOnly mode (true or false)
    ReadOnly=true,
    // (Optional for MD) SaaS mode (true or false)
    SaaSMode=false,
    // Connect to data source
    OdbcDatasource = DuckDB.Contents(Database, MotherDuckToken, ReadOnly, SaaSMode, options)
in
    OdbcDatasource{[Item="test"]}[Data]
