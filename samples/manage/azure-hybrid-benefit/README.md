---
services: Azure SQL
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 12/17/2020
---

# Overview 

This script is provided to help you manage the SQL Server licenses that are consumed by the SQL Servers deployed to Azure. The script writes the results to a `sql-license-usage.csv` file. If the file with this name already exists, the new results will be appended to it. The report includes the following information for each scanned subscription as well as the totals for each  category.
| **Category** | **Description** |
|:--|:--|
|Date|Date of the scan|
|Time|Time of the scan|
|Subscription name|The name of the subscription|
|Subscription ID|The unique subscription ID|
|AHB Std vCores|Total vCores used by General Purpose service tier or SQL Server Standard edition billed with AHB discount|
|AHB Ent vCores|Total vCores used by Business Critical service tier or SQL Server Enterprise edition billed with AHB discount|
|PAYG Std vCores|Total vCores used by General Purpose service tier or SQL Server Standard edition billed at full price|
|PAYG Ent vCores|Total vCores used by Business Critical service tier or SQL Server Enterprise edition billed at full price|
|HADR Std  vCores|Total vCores used by HADR replicas running SQL Server Standard edition|
|HADR Ent vCores|Total vCores used by HADR replicas running SQL Server Enterprise edition|
|Developer vCores|Total vCores used by SQL Server Developer edition|
|Express vCores|Total vCores used by SQL Server Express edition|

>[!NOTE]
> - The usage data is a snapshot at the time of the script execution based on the size of the deployed SQL resources in vCores.
> - For IaaS workloads, such as SQL Server in Virtual Machines or SSIS integration runtimes, each vCPU is counted as one vCore.
> - For PaaS workloads, each vCore of Business Critical service tier is counted as one Enterprise vCore and each vCore of General Purpose service tier is counted as one Standard vCore.

# Running the script using Cloud Shell

Use the following steps to calculate the SQL Server license usage:

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, read [PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
        curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-hybrid-benefit/sql-license-usage.ps1 -o sql-license-usage.ps1
    ```

3. Run the script with a specific subscriptions ID or the file name as the parameter. The file should be used if you need to scan a subset of the subscriptions. If the parameter is not specified, the script will scan all the subscriptions in your account.

    ```console
       ./sql-license-usage.ps1 <subscription ID> or <filename>.csv
    ```

If the a file is specified, it must be a `.csv` file with the list of subscriptions. To create a file containing all subscriptions in your account, use the following command. You can then edit the file to remove the subscriptions you don't want to scan.

    ```console
        Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation
    ```
> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The `curl` command will copy the script directly to the home folder associated with your Cloud Shell session.

# Tracking SQL license usage over time

You can track your license utilization over time by periodically running this script. Each new scan will add the results to  `sql-license-usage.csv`, which you can use for reporting the license usage over time in Excel or other tools. To run this script on schedule using Azure automation, read [Create a PowerShell runbook tutorial](https://docs.microsoft.com/azure/automation/learn/automation-tutorial-runbook-textual-powershell).
