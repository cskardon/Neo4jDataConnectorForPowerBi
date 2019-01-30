// Use this file to write queries to test your data connector
/*
let
    result = Neo4j.Count()
in
    result
*/
/*
let 
	result = Neo4j.GetCountOfNodes()
in
	result
*/

let 
	result = Neo4j.ExecuteCypher("MATCH (n) RETURN COUNT(n)", null, "localhost", 8866)
in
	result