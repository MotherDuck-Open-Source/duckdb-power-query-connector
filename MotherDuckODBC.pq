// This file contains your Data Connector logic
[Version = "1.0.0"]
section MotherDuckODBC;

// When set to true, additional trace information will be written out to the User log.
// This should be set to false before release. Tracing is done through a call to
// Diagnostics.LogValue(). When EnableTraceOutput is set to false, the call becomes a
// no-op and simply returns the original value.
EnableTraceOutput = true;

// The name of the ODBC driver
Config_DriverName = "DuckDB Driver";

// Set to null to determine the value from the driver.
Config_SqlConformance = null;

// DuckDB only supports OFFSET when LIMIT is also specified,
// so we will use LimitClauseKind.Limit.
Config_LimitClauseKind = LimitClauseKind.Limit;

// DuckDB does not support standard username/password
// handling through the UID and PWD connection string parameters.
Config_DefaultUsernamePasswordHandling = false;

// If the driver supports parameter bindings, then set this to true.
Config_UseParameterBindings = null;

// Override this setting to force the character escape value.
Config_StringLiterateEscapeCharacters = null;

// Override this if the driver expects the use of CAST instead of CONVERT.
Config_UseCastInsteadOfConvert = null;

// Set this to true to enable Direct Query in addition to Import mode.
Config_EnableDirectQuery = true;

[DataSource.Kind="MotherDuckODBC", Publish="MotherDuckODBC.Publish"]
shared MotherDuckODBC.Contents = (optional database as text, optional motherduck_token as text, optional options as record) =>
    let
        Config_DriverName = Config_DriverName,
        // The ODBC connection string
        ConnectionString = [
            Driver = Config_DriverName,
            Database = GetFullPath(database, motherduck_token),
            custom_user_agent = "powerbi/v0.0(MotherDuckODBC)"
        ],
        //
        // Configuration options for the call to Odbc.DataSource
        //
        defaultConfig = Diagnostics.LogValue("BuildOdbcConfig", BuildOdbcConfig()),
        SqlCapabilities = Diagnostics.LogValue(
            "SqlCapabilities_Options", defaultConfig[SqlCapabilities] & [
                SupportsTop = false,
                SupportsDerivedTable = true,
                Sql92Conformance = 8 /* SQL_SC_SQL92_FULL */,
                GroupByCapabilities = 4 /* SQL_GB_NO_RELATION */,
                FractionalSecondsScale = 3,
                // Enable Native query
                Sql92Translation = "PassThrough"
            ]
        ),
        // Please refer to the ODBC specification for SQLGetInfo properties and values.
        // https://github.com/Microsoft/ODBC-Specification/blob/master/Windows/inc/sqlext.h
        SQLGetInfo = Diagnostics.LogValue(
            "SQLGetInfo_Options",
            defaultConfig[SQLGetInfo]
                & [
                    // Place custom overrides here
                    // The values below are required for the SQL Native Client ODBC driver, but might
                    // not be required for your data source.
                    SQL_SQL92_PREDICATES = ODBC[SQL_SP][All],
                    SQL_AGGREGATE_FUNCTIONS = ODBC[SQL_AF][All]
                ]
        ),
        // SQLGetTypeInfo can be specified in two ways:
        // 1. A #table() value that returns the same type information as an ODBC
        //    call to SQLGetTypeInfo.
        // 2. A function that accepts a table argument, and returns a table. The
        //    argument will contain the original results of the ODBC call to SQLGetTypeInfo.
        //    Your function implementation can modify/add to this table.
        //
        // For details of the format of the types table parameter and expected return value,
        // please see: https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlgettypeinfo-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLGetTypeInfo = (types) =>
            if (EnableTraceOutput <> true) then
                types
            else
                let
                    // Outputting the entire table might be too large, and result in the value being truncated.
                    // We can output a row at a time instead with Table.TransformRows()
                    rows = Table.TransformRows(types, each Diagnostics.LogValue("SQLGetTypeInfo " & _[TYPE_NAME], _)),
                    toTable = Table.FromRecords(rows)
                in
                    Value.ReplaceType(toTable, Value.Type(types)),
        // SQLColumns is a function handler that receives the results of an ODBC call
        // to SQLColumns(). The source parameter contains a table with the data type
        // information. This override is typically used to fix up data type mismatches
        // between calls to SQLGetTypeInfo and SQLColumns.
        //
        // For details of the format of the source table parameter, please see:
        // https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlcolumns-function
        //
        SQLColumns = (catalogName, schemaName, tableName, columnName, source) =>
            let
                    // Types defined in duckdb/tools/odbc/include/api_info.hpp#L74
                    SQL_BIT = 1,
                    SQL_TINYINT = 3,
                    SQL_SMALLINT = 5,
                    SQL_INTEGER = 11,
                    SQL_BIGINT = 20,
                    SQL_REAL = 14,
                    SQL_FLOAT = 24,
                    SQL_TYPE_DATE = 10,
                    SQL_TYPE_TIME = 9,
                    SQL_TYPE_TIMESTAMP = 20,
                    SQL_VARCHAR = 256,
                    SQL_VARBINARY = 512,
                    FixDataType = (dataType) =>
                        // For debugging purposes, to find out what data types are passed,
                        // uncomment next line and comment rest of code block
                        // error Error.Record("Expression.Error", dataType),
                        if dataType = SQL_BIT then
                            ODBC[SQL_TYPE][BIT]
                        else if dataType = SQL_TINYINT then
                            ODBC[SQL_TYPE][TINYINT]
                        else if dataType = SQL_BIGINT then
                            ODBC[SQL_TYPE][BIGINT]
                        else if dataType = SQL_INTEGER then
                            ODBC[SQL_TYPE][INTEGER]
                        else if dataType = SQL_TYPE_DATE then
                            ODBC[SQL_TYPE][TYPE_DATE]
                        else if dataType = SQL_TYPE_TIME then
                            ODBC[SQL_TYPE][TYPE_TIME]
                        else if dataType = SQL_TYPE_TIMESTAMP then
                            ODBC[SQL_TYPE][TIMESTAMP]
                        else if dataType = SQL_VARCHAR then
                            ODBC[SQL_TYPE][VARCHAR]
                        else if dataType = SQL_VARBINARY then
                            ODBC[SQL_TYPE][VARBINARY]
                        else
                            dataType,
                    Transform = Table.TransformColumns(source, {{"DATA_TYPE", FixDataType}})
           in
                    if (EnableTraceOutput <> true) then
                        Transform
                    else if (
                        // the if statement conditions will force the values to evaluated/written to diagnostics
                        Diagnostics.LogValue("SQLColumns.TableName", tableName) <> "***"
                        and Diagnostics.LogValue("SQLColumns.ColumnName", columnName) <> "***"
                    ) then
                        let
                            // Outputting the entire table might be too large, and result in the value being truncated.
                            // We can output a row at a time instead with Table.TransformRows()
                            rows = Table.TransformRows(Transform, each Diagnostics.LogValue("SQLColumns", _)),
                            toTable = Table.FromRecords(rows)
                        in
                            Value.ReplaceType(toTable, Value.Type(Transform))
                    else
                        Transform,
        Options = [
                // A logical (true/false) that sets whether to view the tables grouped by their schema names
                HierarchicalNavigation = false,
                // Allows upconversion of numeric types
                SoftNumbers = true,
                // Allow upconversion / resizing of numeric and string types
                TolerateConcatOverflow = true,
                // Enables connection pooling via the system ODBC manager
                ClientConnectionPooling = false,
                // Other configuration options
                SqlCapabilities = SqlCapabilities,
                SQLColumns = SQLColumns,
                SQLGetInfo = SQLGetInfo,
                SQLGetTypeInfo = SQLGetTypeInfo
            ],
        // Create and return the ODBC data source
        OdbcDatasource = Odbc.DataSource(
            ConnectionString,
            Options
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
