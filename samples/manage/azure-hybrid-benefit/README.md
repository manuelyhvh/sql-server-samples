---
services: Azure SQL
platforms: Azure
author: anosov1960
ms.author: sashan
ms.date: 12/15/2020
---

# Overview 

This script is provided to help you manage the SQL Server licenses that are consumed by the SQL Servers deployed to Azure. The script's output is a `sql-license-usage.csv` file with the consolidated SQL Server license usage by all SQL resources in the specific subscriptions or the entire account. The usage is broken down into the following categories of licenses:

- AHB Standard vCores
- AHB Enterprise vCores
- PAYG Standard vCores
- PAYG Enterprise vCores
- HADR Standard vCores
- HADR Enterprise vCores
- Developer vCores
- Express vCores

>[!NOTE]
> - The usage data is a snapshot at the time of the script execution based on the size of the deployed SQL resources in vCores.
> - For IaaS workloads, such as SQL Server in Virtual Machines or SSIS integration runtimes, each vCPU is counted as one vCore.
> - For PaaS workloads, each vCore of Business Critical service tier is counted as one Enterprise vCore and each vCore of General Purpose service tier is counted as one Standard vCore.


# Running the script using Cloud Shell

Use the following steps to calculate the SQL Server license usage:

1. Launch the [Cloud Shell](https://shell.azure.com/). For details, [read more about PowerShell in Cloud Shell](https://aka.ms/pscloudshell/docs).

2. Upload the script to the shell using the following command:

    ```console
        curl https://raw.githubusercontent.com/microsoft/sql-server-samples/master/samples/manage/azure-hybrid-benefit/sql-license-usage.ps1 -o sql-license-usage.ps1
    ```

3. Run the script in interactive mode. The script will prompt for a subscriptions ID or `*`. The latter will automatically scan all the subscriptions in you account.

    ```console
       ./sql-license-usage.ps1
    ```

If you need to scan a subset of the subscriptions, use the following steps:

1. Create a `.csv` with the list off all subscriptions in your account using the following command. You can edit the file to remove the subscriptions you don't want to scan.

    ```console
        Get-AzSubscription | Export-Csv .\mysubscriptions.csv -NoTypeInformation
    ```

2. Run the script and specify the `.csv` file as a parameter.
    ```console
   ./sql-license-usage.ps1 .\mysubscriptions.csv
    ```

> [!NOTE]
> - To paste the commands into the shell, use `Ctrl-Shift-V` on Windows or `Cmd-v` on MacOS.
> - The script will be uploaded directly to the home folder associated with your Cloud Shell session.
> - The script will prompt for the resource group name and print a message when migration is completed.

