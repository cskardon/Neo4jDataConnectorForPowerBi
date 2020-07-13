# Neo4j DataConnector For Power BI

Pretty much what it says on the tin. 

## How do I try it?

1. Put it into your PowerBI extensions folder
  (which appears to be: `<USER>/Documents/Power BI Desktop/Custom Connectors`) 
2. Allow Power BI to use beta connectors:
  Goto 'Options' in Power BI
  Select 'Security'
  Under the 'Data Extensions' heading select the radio option of:
  > (Not Recommended) Allow any extension to load without validation or warning

## Releases

All releases are available on the [Releases](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases) page.

## Versions

* [1.0](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases/tag/1.0.0) = Initial release
* [1.1](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases/tag/1.1.0) = Bug fix to get it working with Neo4j 4.0 MR2 (and probably onwards)
* [1.2](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases/tag/1.2.0) = Neo4j `4.0` release - should work with `3.x` and `4.x`
* [1.3](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases/tag/1.3.0) = Adding `Timeout` settings for longer running queries

## Beta Versions

* [1.4beta](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/releases/tag/1.4.0-beta) = Adding Auto-refresh support -- [Issue #1](https://github.com/cskardon/Neo4jDataConnectorForPowerBi/issues/1)