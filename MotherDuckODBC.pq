// This file contains your Data Connector logic
[Version = "1.0.0"]
section MotherDuckODBC;

[DataSource.Kind="MotherDuckODBC", Publish="MotherDuckODBC.Publish"]
shared MotherDuckODBC.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from MotherDuckODBC: " & _message
    in
        a;

// Data Source Kind description
MotherDuckODBC = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Anonymous = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
MotherDuckODBC.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = MotherDuckODBC.Icons,
    SourceTypeImage = MotherDuckODBC.Icons
];

MotherDuckODBC.Icons = [
    Icon16 = { Extension.Contents("MotherDuckODBC16.png"), Extension.Contents("MotherDuckODBC20.png"), Extension.Contents("MotherDuckODBC24.png"), Extension.Contents("MotherDuckODBC32.png") },
    Icon32 = { Extension.Contents("MotherDuckODBC32.png"), Extension.Contents("MotherDuckODBC40.png"), Extension.Contents("MotherDuckODBC48.png"), Extension.Contents("MotherDuckODBC64.png") }
];
