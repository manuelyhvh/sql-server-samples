# Release notes for SQL Assessment API

This article provides details about updates, improvements, and bug fixes for the current and previous versions of SQL Assessment API. SQL Assessment API is part of the SQL Server Management Objects (SMO) and the SQL Server PowerShell module. Install one of them or both to start working with the API.

Download: [Download SqlServer module](https://www.powershellgallery.com/packages/SqlServer)

Download: [SMO NuGet Package](https://www.nuget.org/packages/Microsoft.SqlServer.SqlManagementObjects)

You can use GitHub issues to provide feedback to the product team.

## March 2020 - 21.1.18221

Version: SqlServer module 21.1.18221, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Platform, Name, and engineEdition fields can now contain usual comma-separated lists ("platform": \["Windows", "Linux"\]), not only regular expressions ("platform": "/Windows|Linux/")
- Added rule "Database files have a growth ratio set in percentage"
- Added rule "STRelate and STAsBinary functions unexpected results due to TF 6533 enabled"
- Added rule "Database Integrity Checks"
- Added rule "Direct Catalog Updates"
- Added rule "Data Purity Check"
- Added rule "MaxDOP should be less or equal number of CPUs"
- Added rule "MaxDOP should equal number of CPUs for single NUMA node"
- Added rule "MaxDOP should be less 8 for single NUMA node"
- Added rule "MaxDOP should be according to processor count ratio"
- Added rule "Pending disk I/O requests"
- Added rule "Index Fragmentation"
- Added rule "Untrusted Constraints"
- Added rule "Statistics need to be updated"

### Bug fixes

- Wrong help link in XTPHashAvgChainBuckets rule
- Occasional error "There is already an open DataReader associated with this Command which must be closed first" on PowerShell 7

## December 2019 - 21.1.18218

Version: SqlServer module 21.1.18206, SqlManagementObjects (SMO) package wasn't updated

### What's new

- Added .DLL with types to get rid of recompilation of CLR probes assemblies every time when new version of solution is released
- Updated Deprecated Features rules and Index rules to not run them against system DBs
- Updated rules High CPU Usage: kept only one, added overridable threshold
- Updated some rules to not run them against SQL Server 2008
- Added timestamp property to rule object

### Bug fixes

- Error "Missing data item 'FilterDefinition'" when overriding Exclusion DB List
- Probe of rule Missed Indexes returns nothing
- FullBackup rule has threshold in days but gets backup age in hours
- When database can't be accessed and it's disabled for assessment, it throws access errors when performing assessment

## GA - November 2019 - 21.1.18206

Version: SqlServer module 21.1.18206, SqlManagementObjects (SMO) package 150.208.0

### What's new

- Added 50 assessment rules
- Added base math expressions and comparisons to rules conditions
- Added support for RegisteredServer object
- Updated way how rules are stored in the JSON format and also updated the mechanism of applying overrides/customizations
- Updated rules to support SQL on Linux
- Updated the ruleset JSON format and added SCHEMA version
- Updated cmdlets output to improve readability of recommendations

### Bug fixes

- Rules were revised and some were fixed
- Broken order of recommendations
- Error messages are not clear

### Known issues

- Invoke-SqlAssessment may crash with message "Missing data item 'FilterDefinition'" on some databases. If you face this issue, create a customization to disable the RedundantIndexes rule to disable it. See README.md to learn how to disable rules. We'll fix this issue with the next release.

- Assemblies providing methods for CLR probes should be recompiled for each new release of SQL Assessment API.
