//////////////////////////////////////////////////////////////////////////////////////////////
// Neo4j Connector for Power BI
//   From: https://github.com/cskardon/Neo4jDataConnectorForPowerBi
//   License details all at the github page, but if you don't want to browse - it's MIT
section Neo4j;

//////////////////////////////////////////////////////////////////////////////////////////////
// Public Functions
//   This is badly titled, as technically, only the 'shared' function is public, but the other
//   2 are in this section as they are the 'meat' of the data connector.

//
// This is the _shared_ definition which exports the function to be visible to PowerBI
// NB. The `Value.ReplaceType` call is there to allow the UI to render the 'help' text defined in the `ExecuteCypherType`
//
[DataSource.Kind="Neo4j", Publish="Neo4j.Publish"]
shared Neo4j.ExecuteCypher = Value.ReplaceType(ExecuteCypherImpl, ExecuteCypherType);

//
// This is the type definition - providing hints on the PowerBI UI
//
ExecuteCypherType = type function (
    cypher as (type text meta [
            Documentation.FieldCaption = Extension.LoadString("CypherCaption"),
            Documentation.FieldDescription = Extension.LoadString("CypherDescription"),
            Formatting.IsMultiLine = true,
            Formatting.IsCode = true,
            Documentation.SampleValues = {"MATCH (n) RETURN n", "MATCH (n) RETURN COUNT(n)"}
    ]),
    scheme as (type text meta [
            Documentation.FieldCaption = Extension.LoadString("SchemeCaption"),
            Documentation.FieldDescription = "The scheme to connect to your Neo4j instance",
            Documentation.SampleValues = {"http", "https"}//,
            //Documentation.AllowedValues = { "http", "https" }
    ]),
    address as (type text meta [
            Documentation.FieldCaption = Extension.LoadString("AddressCaption"),
            Documentation.FieldDescription = Extension.LoadString("AddressDescription"),
            Documentation.SampleValues = {"localhost.", "127.0.0.1"}
    ]),
    port as (type number meta [
            Documentation.FieldCaption = Extension.LoadString("PortCaption"),
            Documentation.FieldDescription = Extension.LoadString("PortDescription"),
            Documentation.SampleValues = {"7474"}
    ]),
    neo4jVersion as (type number meta [
            Documentation.FieldCaption = Extension.LoadString("Neo4jVersionCaption"),
            Documentation.FieldDescription = Extension.LoadString("Neo4jVersionDescription"),
            Documentation.SampleValues = {3.5, 4.2}//,
            //Documentation.AllowedValues = {3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 4.0, 4.1, 4.2, 4.3}
    ]),
    databaseName as (type text meta [
            Documentation.FieldCaption = Extension.LoadString("DatabaseNameCaption"),
            Documentation.FieldDescription = Extension.LoadString("DatabaseNameDescription"),
            Documentation.SampleValues = {"neo4j", "hr"}
    ]),
    timeout as (type number meta [
            Documentation.FieldCaption = Extension.LoadString("TimeoutCaption"),
            Documentation.FieldDescription = Extension.LoadString("TimeoutDescription"),
            Documentation.SampleValues = {30}
    ])
) as table meta [
        Documentation.Name = Extension.LoadString("ConnectorName"),
        Documentation.LongDescription = Extension.LoadString("ConnectorDescription")
    ];

///
/// This is based on the blog post at: http://xclave.co.uk/2017/06/22/using-powerbi-with-neo4j/ 
/// taking into account the comments from 'Will' - to get the column output using the names returned from the query
///
ExecuteCypherImpl = (
            cypher as text,
            scheme as text,
            address as text, 
            port as number,
            neo4jVersion as number,
            databaseName as text,
            timeout as number) as table =>
    let
        _source = Neo4j.ExecuteRestCall(cypher, scheme, address, port, neo4jVersion, databaseName, timeout),
        _json = Json.Document(_source),
        _results = _json[results],
        _results1 = _results{0},
        _data = _results1[data],
        _columns = _results1[columns],
        _tabledResults = Table.FromList(_data, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
        _rows = Table.ExpandRecordColumn(_tabledResults, "Column1", {"row"}, {"Column1.row"}),
        _column1Row = _rows[Column1.row],
        table = Table.FromRows(_column1Row, _columns)
    in 
        table;

  
//////////////////////////////////////////////////////////////////////////////////////////////
// Private Functions

Neo4j.ExecuteRestCall = (
            cypher as text,
            scheme as nullable text,
            address as nullable text, 
            port as nullable number,
            neo4jVersion as nullable number,
            databaseName as nullable text,
            timeout as nullable number) as binary =>
try
    let
        content = Web.Contents(Neo4j.DefaultUri(scheme, address, port, neo4jVersion, databaseName), [
            Headers = if Extension.CurrentCredential()[AuthenticationKind] = "Implicit" then ImplicitRequestHeaders else DefaultRequestHeaders,
            Content = Neo4j.CypherToM(cypher),
            Timeout=#duration(0,0,0,Neo4j.GetTimeout(timeout))
        ])    
    in 
        content
otherwise
    let 
        message = Text.Format("Error executing the call against the database.#(cr)#(lf)Cypher was: '#[cypher]'#(cr)#(lf)NB. Cypher shown is how it was formatted to send to Neo4j.", [cypher=Neo4j.CleanCyper(cypher)])
    in 
        Diagnostics.Trace(TraceLevel.Error, message, () => error message, true);


//
// Generates the default request headers needed for Neo4j to work
//
DefaultRequestHeaders = [
    #"Authorization" = "Basic " & Neo4j.Encode(Extension.CurrentCredential()[Username], Extension.CurrentCredential()[Password]),
    #"Content-Type"="application/json"
];

ImplicitRequestHeaders = [
    #"Content-Type"="application/json"
];

//
// Generates the URI to connect to, taking the scheme, address and port - if these aren't supplied, defaults will be used.
//  scheme: 'http'
//  address: 'localhost'
//  port: 7474
//  version: 3.5
//  databaseName: neo4j
//
Neo4j.DefaultUri = (optional scheme as nullable text, optional address as nullable text, optional port as nullable number, optional neo4jVersion as nullable number, optional databaseName as nullable text) =>
    let
        _version = if(neo4jVersion) is null then 4.2 else neo4jVersion,
        _databaseName = if(databaseName) is null then "neo4j" else databaseName,
        _transactionEndPoint = if(_version) < 4.0 then "db/data/transaction/commit" else "db/" & _databaseName & "/tx",
        _port = if (port) is null then 7474 else port,
        _address = if address is null then "localhost." else address,
        _scheme = if scheme is null then "http" else scheme,
        uri = _scheme & "://" & _address & ":" & Text.From(_port) & "/" & _transactionEndPoint
    in
        uri;

//
// Encodes a username/password into a combined base64 string of {user}:{password}
//
Neo4j.Encode = (user as text, password as text) =>
    let
        encoded = Binary.ToText(Text.ToBinary(user & ":" & password), 0)
    in
        encoded;

//
// Takes the cypher given and converts it into a structure Neo4j expects at the Transaction Endpoint
//
Neo4j.CypherToM = (cypher as text) =>
    let 
        cleanCypher = Neo4j.CleanCyper(cypher),
        binary = Text.ToBinary("{
                    ""statements"" : [ {
                    ""statement"" : "" " & cleanCypher & " ""} ]
                    }")
    in
        binary;

//
// Clean the Cypher - removing CRLF characters
//
Neo4j.CleanCyper = (cypher as text) =>
    let 
        cleanCypher = Text.Replace(Text.Replace(Text.Replace(Text.Replace(Text.Replace(cypher, "#(cr)", " "), "#(lf)", " "), "\u000d", " "), "\u000a", " "), Character.FromNumber(34), "\""")
    in 
        cleanCypher;

//
// Gets the default timeout (30s) or the value set.
//
Neo4j.GetTimeout = (timeout as nullable number) =>
    let 
        _timeout = if(timeout) is null then 30 else timeout
    in
        _timeout;

//////////////////////////////////////////////////////////////////////////////////////////////
// Connector Definitions

//
// Connector definition, allows access via User/Password combinations and Anonymous (Implicit)
//
Neo4j = [
    TestConnection = (datasourcePath) => 
        let
            json = Json.Document(datasourcePath),
            cypher = json[cypher],
            scheme = json[scheme],
            address = json[address],
            port = json[port],
            neo4jVersion = json[neo4jVersion],
            databaseName = json[databaseName],
            timeout  = json[timeout]
        in
            {"Neo4j.ExecuteCypher", cypher, scheme, address, port, neo4jVersion, databaseName, timeout },
    Authentication = [
        UsernamePassword = [
            Label = "Neo4j Authentication",
            UsernameLabel = "Username",
            PasswordLabel = "Password"
        ],
        Anonymous = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

//
// The UI Publishing definition, i.e. where it shows in the UI, whether it's beta etc
//
Neo4j.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://github.com/cskardon/Neo4jDataConnectorForPowerBi/",
    SourceImage = Neo4j.Icons,
    SourceTypeImage = Neo4j.Icons
];

// 
// Various sized icons for UI display
//
Neo4j.Icons = [
    Icon16 = { Extension.Contents("Neo4j16.png"), Extension.Contents("Neo4j20.png"), Extension.Contents("Neo4j24.png"), Extension.Contents("Neo4j32.png") },
    Icon32 = { Extension.Contents("Neo4j32.png"), Extension.Contents("Neo4j40.png"), Extension.Contents("Neo4j48.png"), Extension.Contents("Neo4j64.png") }
];