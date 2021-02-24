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
    result = Neo4j.ExecuteCypher("MATCH (n:Movie) WHERE n.title = ""The Matrix"" RETURN n", "http", "localhost.", 7474, 2.4, "neo4j", 30)
in
    result

    /*
let 
    result = Neo4j.ExecuteCypher("MATCH (n) RETURN COUNT(n)", "http", "Server2019Blog", 7474, 4.2, "neo4j", 30)
in
    result
    */

/*
let 
    result = Neo4j.ExecuteCypher("MATCH (n) RETURN COUNT(n)", "http", "localhost", 7474, 4.1, "neo4j", 30)
in
    result
*/