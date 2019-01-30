/*2
 * Neo4j Connector for PowerBI
 */
section Neo4j;

DefaultRequestHeaders = [
    #"Authorization" = "Basic " & Neo4j.Encode(Extension.CurrentCredential()[Username], Extension.CurrentCredential()[Password])
];

[DataSource.Kind="Neo4j", Publish="Neo4j.Publish"]
shared Neo4j.ExecuteCypher = Value.ReplaceType(ExecuteCypherImpl, ExecuteCypherType);


ExecuteCypherType = type function (
 cypher as (type text meta [
        Documentation.FieldCaption = "Cypher",
        Documentation.FieldDescription = "Enter your Cypher query here",
        Documentation.SampleValues = {"MATCH (n) RETURN n", "MATCH (n) RETURN COUNT(n)"}
    ]),
optional scheme as (type text meta [
		Documentation.FieldDescription = "The scheme to connect to your Neo4j instance",
        Documentation.SampleValues = {"http", "https"},
		Documentation.AllowedValues = { "http", "https" }
]),
 optional address as (type text meta [
 Documentation.FieldCaption = "Address",
        Documentation.FieldDescription = "The address for your Neo4j instance",
        Documentation.SampleValues = {"localhost.", "127.0.0.1"}
 ]),
 optional port as (type number meta [
        Documentation.FieldCaption = "Port",
        Documentation.FieldDescription = "The port of the Neo4j instance",
        Documentation.SampleValues = {"7474"}])
) as table meta [
		Documentation.Name = "Execute Cypher - Output",
        Documentation.LongDescription = "Provides the response of the query in a Json document"];


///
/// This is based on the blog post at: http://xclave.co.uk/2017/06/22/using-powerbi-with-neo4j/ 
/// taking into account the comments from 'Will' - to get the column output using the names returned from the query
///
ExecuteCypherImpl = (
			cypher as text,
			optional scheme as nullable text,
			optional address as nullable text, 
			optional port as nullable number) as table =>
let
    _source = Web.Contents(Neo4j.DefaultUri(scheme, address, port), [
        Headers = if Extension.CurrentCredential()[AuthenticationKind] = "Implicit" then null else  DefaultRequestHeaders,
        Content = Neo4j.CypherToM(cypher)
    ]),
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

/*
 * Private Functions
 */

Neo4j.DefaultUri = (optional scheme as nullable text, optional address as nullable text, optional port as nullable number) =>
	let
		_transactionEndPoint = "db/data/transaction/commit",
		_port = if (port) is null then 7474 else port,
		_address = if address is null then "localhost." else address,
		_scheme = if scheme is null then "http" else scheme,
		uri = _scheme & "://" & _address & ":" & Text.From(_port) & "/" & _transactionEndPoint
	in
		uri;


 /// Encodes a username/password into a combined base64 string of {user}:{password}
Neo4j.Encode = (user as text, password as text) =>
    let
        encoded = Binary.ToText(Text.ToBinary(user & ":" & password), 0)
    in
        encoded;

/// Takes the cypher given and converts it into a structure Neo4j expects at the Transaction Endpoint
Neo4j.CypherToM = (cypher as text) =>
    let 
        binary = Text.ToBinary("{
                    ""statements"" : [ {
                    ""statement"" : "" " & cypher & " ""} ]
                    }")
    in
        binary;

/*
 * Definition of the connector
 */
Neo4j = [
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

/*
 * Data Source UI publishing description
 */

Neo4j.Publish = [
    Beta = true,
    Category = "Database",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://neo4j.com/",
    SourceImage = Neo4j.Icons,
    SourceTypeImage = Neo4j.Icons
];

Neo4j.Icons = [
    Icon16 = { Extension.Contents("Neo4j16.png"), Extension.Contents("Neo4j20.png"), Extension.Contents("Neo4j24.png"), Extension.Contents("Neo4j32.png") },
    Icon32 = { Extension.Contents("Neo4j32.png"), Extension.Contents("Neo4j40.png"), Extension.Contents("Neo4j48.png"), Extension.Contents("Neo4j64.png") }
];