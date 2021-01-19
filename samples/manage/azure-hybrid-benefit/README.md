---
services: Azure SQL
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 1/11/2021
---

# Overview

This script provides a simple solution to analyze and track the consolidated utilization of SQL Server licenses by all of the SQL resources in a specific subscription or the entire the account. By default, the script scans all subscriptions the user account has access. Alternatively, you can specify a single subscription or a .CSV file with a list of subscription. The usage report includes the following information for each scanned subscription.

| **Category** | **Description** |
|:--|:--|
|Date|Date of the scan|
|Time|Time of the scan|
|Subscription name|The name of the subscription|
|Subscription ID|The unique subscription ID|
|AHB Std vCores|Total vCores used by General Purpose service tier or SQL Server Standard edition billed with hybrid benefit  discount|
|AHB Ent vCores|Total vCores used by Business Critical service tier or SQL Server Enterprise edition billed with hybrid benefit  discount|
|PAYG Std vCores|Total vCores used by General Purpose service tier or SQL Server Standard edition billed at full price|
|PAYG Ent vCores|Total vCores used by Business Critical service tier or SQL Server Enterprise edition billed at full price|
|HADR Std  vCores|Total vCores used by HADR replicas running SQL Server Standard edition|
|HADR Ent vCores|Total vCores used by HADR replicas running SQL Server Enterprise edition|
|Developer vCores|Total vCores used by SQL Server Developer edition|
|Express vCores|Total vCores used by SQL Server Express edition|

The following resources are in scope for the license utilization analysis:
- Azure SQL databases (vCore-based purchasing model only) 
- Azure SQL elastic pools (vCore-based purchasing model only)
- Azure SQL managed instances
- Azure SQL instance pools
- Azure Data Factory SSIS integration runtimes
- SQL Servers in Azure virtual machines 
- SQL Servers in Azure virtual machines hosted in Azure dedicated host

>[!NOTE]
> - The usage data is a snapshot at the time of the script execution based on the size of the deployed SQL resources in vCores.
> - For IaaS workloads, such as SQL Server in Virtual Machines or SSIS integration runtimes, each vCPU is counted as one vCore.
> - For PaaS workloads, each vCore of Business Critical service tier is counted as one Enterprise vCore and each vCore of General Purpose service tier is counted as one Standard vCore.
> - In the DTU-based purchasing model, the SQL license cost is built into the individual SKU prices. These resources are not eligible for Azure Hybrid Benefit or HADR benefit, and therefore are not in scope of the tool.
> - The values AHB ECs and PAYG ECs are reserved for the future use and should be ignored

# Launching the script 

The script accepts the following command line parameters:

| **Parameter** &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;  | **Value** | **Description** |
|:--|:--|:--|
|-SubId|subscription_id *or* a file_name|Accepts a .csv file with the list of subscriptions<sup>1</sup>|
|-UseInRunbook||Must be specified when executed as a Runbook|
|-Server|[protocol:]server[instance_name][,port]|Required to save data to the database| 
|-Database|database_name|Required to save data to the database|
|-Username|user_name|Required to save data to the database|
|-Password|password|Required to save data to the database, must be passed as a *[SecureString]* variable|
|-FilePath|csv_file_name|Required to save data in a .csv format. Ignored if database parameters are specified|

<sup>1</sup>You can create a .csv file using the following command and then edit to remove the subscriptions you don't  want to scan.
```PowerShell
Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation 
```
If both database parameters and *FilePath* are omitted, the script will write the results to a `.\sql-license-usage.csv` file. The file is created automatically. If the file already exists, the consecutive scans will append the results to it. If the database parameters are specified, the data will be saved in a *Usage-per-subscription* table. If the table doesn't exist, it will be created automatically.

## Example 1

The following command will scan all the subscriptions in the account and save the results in `.\sql-license-usage.csv`

```PowerShell
.\sql-license-usage.ps1
```

## Example 2

The following command will scan the subscription `<sub_id>` and save the results in `<my_csv_file>` file.

```PowerShell
.\sql-license-usage.ps1 -SubId <sub_id> -FilePath .\<my_csv_file>.csv
```

## Example 3

The following command will scan all the subscriptions in the account and save the results in a SQL database `<db_name>` on a SQL Server instance `<sql_server_name>.database.windows.net`.

```PowerShell
$cred = Get-Credential -credential <user_name>
.\sql-license-usage.ps1 -Server <server_name>.database.windows.net -Database <db_name> -Username $cred.Username -Password $cred.Password
```

# Running the script using Cloud Shell

Use the following steps to calculate the SQL Server license usage:

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, read [PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
        curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-hybrid-benefit/sql-license-usage.ps1 -o sql-license-usage.ps1
    ```

3. Run the script with a set of parameters that reflect your desired configuration.

    ```console
       ./sql-license-usage.ps1 <parameters>
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The `curl` command will copy the script directly to the home folder associated with your Cloud Shell session.

# Tracking SQL license usage over time

You can track your license utilization over time by periodically running this script. To schedule automatic execution of the script, create a PowerShell runbook using an Azure Automation account. See the [Runbook tutorial](https://docs.microsoft.com/en-us/azure/automation/learn/automation-tutorial-runbook-textual-powershell) for the details of how to create a PowerShell runbook. Because the script accesses the resources across multiple subscriptions, the runbook must be able to authenticate using the Run As account that was automatically created when you created your Automation account. The logic required for the Runbooks is part of the script.

>[!IMPORTANT]
> - When running the script as a runbook, use a database to ensure that the results can be analyzed outside of the runbook.
> - You must specify a *-UseInRunbook* switch to ensure that the runbook is authenticated using the Run As account.