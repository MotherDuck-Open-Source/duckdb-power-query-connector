// This file contains your Data Connector logic
[Version = "1.0.0"]
section MotherDuckODBC;

EnableTraceOutput = true;
Config_DriverName = "DuckDB Driver";
Config_SqlConformance = null;
Config_LimitClauseKind = LimitClauseKind.Limit;
Config_DefaultUsernamePasswordHandling = false;
Config_UseParameterBindings = null;
Config_StringLiterateEscapeCharacters = null;
Config_UseCastInsteadOfConvert = null;
Config_EnableDirectQuery = true;

[DataSource.Kind="MotherDuckODBC", Publish="MotherDuckODBC.Publish"]
shared MotherDuckODBC.Contents = (optional database as text, optional motherduck_token as text, optional options as record) =>
    let
        // The name of the ODBC driver
        Config_DriverName = "DuckDB Driver",
        // The ODBC connection string
        ConnectionString = [
            Driver = Config_DriverName,
            Database = GetFullPath(database, motherduck_token),
            custom_user_agent = "Microsoft Power Query/MotherDuckODBC/v0.0"
        ],
        // Create and return the ODBC data source
        OdbcDatasource = Odbc.DataSource(
            ConnectionString,
            [
                // A logical (true/false) that sets whether to view the tables grouped by their schema names
                HierarchicalNavigation = false,
                // Allows upconversion of numeric types
                SoftNumbers = true,
                // Allow upconversion / resizing of numeric and string types
                TolerateConcatOverflow = true,
                // Enables connection pooling via the system ODBC manager
                ClientConnectionPooling = true
            ]
        )
    in
        OdbcDatasource;

// Data Source Kind description
MotherDuckODBC = [
    // Set the TestConnection handler to enable gateway support.
    // The TestConnection handler will invoke your data source function to
    // validate the credentials the user has provider. Ideally, this is not
    // an expensive operation to perform. By default, the dataSourcePath value
    // will be a json string containing the required parameters of your data
    // source function. These should be parsed and parsed as individual parameters
    // to the specified data source function.
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath), server = json[server]
            // name of function parameter
        in
            {"SqlODBC.Contents", server},
    // Set supported types of authentication
    Authentication = [
        Windows = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
MotherDuckODBC.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SupportsDirectQuery = Config_EnableDirectQuery,
    SourceImage = MotherDuckODBC.Icons,
    SourceTypeImage = MotherDuckODBC.Icons
];

MotherDuckODBC.Icons = [
    Icon16 = { Extension.Contents("MotherDuckODBC16.png"), Extension.Contents("MotherDuckODBC20.png"), Extension.Contents("MotherDuckODBC24.png"), Extension.Contents("MotherDuckODBC32.png") },
    Icon32 = { Extension.Contents("MotherDuckODBC32.png"), Extension.Contents("MotherDuckODBC40.png"), Extension.Contents("MotherDuckODBC48.png"), Extension.Contents("MotherDuckODBC64.png") }
];

// Get the full DuckDB path to pass to the ODBC driver
GetFullPath = (database as text, optional motherduck_token as text) as text =>
    let
        path = if IsMotherDuckDatabase(database)
            then database & "?motherduck_token=" & motherduck_token
            else database
    in
        if IsMotherDuckDatabase(database) and (motherduck_token = null or motherduck_token = "")
        then
            error Error.Record("Expression.Error",
            "Cannot connect to MotherDuck database:
            Please enter your connection token.
            Go to http://app.motherduck.com/ and copy
            it from your User Settings.")
        else
            path;

// Check if the database is a MotherDuck database
IsMotherDuckDatabase = (database as text) as logical =>
    let
        result = Text.StartsWith(database, "md:")
    in
        result;

// build settings based on configuration variables
BuildOdbcConfig = () as record =>
    let
        Merge = (previous as record, optional caps as record, optional funcs as record, optional getInfo as record) as record =>
            let
                newCaps = if (caps <> null) then previous[SqlCapabilities] & caps else previous[SqlCapabilities],
                newFuncs = if (funcs <> null) then previous[SQLGetFunctions] & funcs else previous[SQLGetFunctions],
                newGetInfo = if (getInfo <> null) then previous[SQLGetInfo] & getInfo else previous[SQLGetInfo]
            in
                [SqlCapabilities = newCaps, SQLGetFunctions = newFuncs, SQLGetInfo = newGetInfo],
        defaultConfig = [
            SqlCapabilities = [],
            SQLGetFunctions = [],
            SQLGetInfo = []
        ],
        withParams =
            if (Config_UseParameterBindings = false) then
                let
                    caps = [
                        SupportsNumericLiterals = true,
                        SupportsStringLiterals = true,
                        SupportsOdbcDateLiterals = true,
                        SupportsOdbcTimeLiterals = true,
                        SupportsOdbcTimestampLiterals = true
                    ],
                    funcs = [
                        SQL_API_SQLBINDPARAMETER = false
                    ]
                in
                    Merge(defaultConfig, caps, funcs)
            else
                defaultConfig,
        withEscape =
            if (Config_StringLiterateEscapeCharacters <> null) then
                let
                    caps = [
                        StringLiteralEscapeCharacters = Config_StringLiterateEscapeCharacters
                    ]
                in
                    Merge(withParams, caps)
            else
                withParams,
        withLimitClauseKind = let caps = [
            LimitClauseKind = Config_LimitClauseKind
        ] in Merge(withEscape, caps),
        withCastOrConvert =
            if (Config_UseCastInsteadOfConvert <> null) then
                let
                    value =
                        if (Config_UseCastInsteadOfConvert = true) then
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CAST]
                        else
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CONVERT],
                    getInfo = [
                        SQL_CONVERT_FUNCTIONS = value
                    ]
                in
                    Merge(withLimitClauseKind, null, null, getInfo)
            else
                withLimitClauseKind,
        withSqlConformance =
            if (Config_SqlConformance <> null) then
                let
                    getInfo = [
                        SQL_SQL_CONFORMANCE = Config_SqlConformance
                    ]
                in
                    Merge(withCastOrConvert, null, null, getInfo)
            else
                withCastOrConvert
    in
        withSqlConformance;

ValidateOptions = (options as nullable record, validOptionsMap as table) as record =>
    let
        ValidKeys = Table.Column(validOptionsMap, "Name"),
        InvalidKeys = List.Difference(Record.FieldNames(options), ValidKeys),
        InvalidKeysText =
            if List.IsEmpty(InvalidKeys) then
                null
            else
                Text.Format(
                    "'#{0}' are not valid options. Valid options are: '#{1}'",
                    {Text.Combine(InvalidKeys, ", "), Text.Combine(ValidKeys, ", ")}
                ),
        ValidateValue = (name, optionType, description, default, validate, value) =>
            if
                (value is null and (Type.IsNullable(optionType) or default <> null))
                or (Type.Is(Value.Type(value), optionType) and validate(value))
            then
                null
            else
                Text.Format(
                    "This function does not support the option '#{0}' with value '#{1}'. Valid value is #{2}.",
                    {name, value, description}
                ),
        InvalidValues = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    ValidateValue(
                        [Name],
                        [Type],
                        [Description],
                        [Default],
                        [Validate],
                        Record.FieldOrDefault(options, [Name], [Default])
                    )
            )
        ),
        DefaultOptions = Record.FromTable(
            Table.RenameColumns(Table.SelectColumns(validOptionsMap, {"Name", "Default"}), {"Default", "Value"})
        ),
        NullNotAllowedFields = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    if not Type.IsNullable([Type]) and null = Record.FieldOrDefault(options, [Name], [Default]) then
                        [Name]
                    else
                        null
            )
        ),
        NormalizedOptions = DefaultOptions & Record.RemoveFields(options, NullNotAllowedFields, MissingField.Ignore)
    in
        if null = options then
            DefaultOptions
        else if not List.IsEmpty(InvalidKeys) then
            error Error.Record("Expression.Error", InvalidKeysText)
        else if not List.IsEmpty(InvalidValues) then
            error Error.Record("Expression.Error", Text.Combine(InvalidValues, ", "))
        else
            NormalizedOptions;

//
// Load common library functions
//
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");

Diagnostics.LogValue = if (EnableTraceOutput) then Diagnostics[LogValue] else (prefix, value) => value;

// OdbcConstants contains numeric constants from the ODBC header files, and a
// helper function to create bitfield values.
ODBC = Extension.LoadFunction("OdbcConstants.pqm");
