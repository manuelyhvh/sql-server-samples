# Always Encrypted with secure enclaves in Azure SQL Database - Demos

The below demos show case [Always Encrypted with secure enclaves](https://docs.microsoft.com/azure/azure-sql/database/always-encrypted-with-secure-enclaves-landing) in Azure SQL database.

## Contents

1. [Prerequisites](#Prerequisites)
1. [Demo 1](#demo-1)
1. [Demo 2](#demo-2)

## Prerequisites

The below demo steps assume you have met the prerequisites listed in [Prerequisites](../README.md#prerequisites) and you have set up your demo environment by following the instructions in [Setup](../README.md#setup). Make sure you have the information about your environment, the setup script has produced:
  - The demo resource group name (`<project name>`)
  - The database server name (`<project name>server.database.windows.net`)
  - The database name (`ContosoHR`)
  - The attestation URL (`https://<project name>attest.<region moniker>.attest.azure.net/attest/SgxEnclave`)
- The application URL (`https://<project name>app.azurewebsites.net/`)

## Demo 1

This short demo highlights the benefits of Always Encrypted with secure enclaves and, optionally, provides a tour of the demo environment, in which the secure enclave is already set up and sensitive data columns in the database are already encrypted.

### Prepare for the demo
Perform the below steps before you show the demo.

1. Prepare SQL Server Management Studio (SSMS).
    1. Start SSMS.
    1. In the Connect to Server dialog:
        1. Enter your database server name. 
        1. Set Authentication to Azure Active Directory – Universal with MFA.
        1. In the User Name field, enter your Azure AD username, you've used to sign in to Azure, when you set up your demo environment.
        1. Click the Options >> button.
        1. Select the Connection Properties tab.
        1. Enter the database name.
        1. Select the Always Encrypted tab.
        1. Make sure Enable Always Encrypted is not selected.
        1. Click Connect.
        1. When prompted, sign in to Azure.
    1. Configure query windows.
        1. In Object Explorer, find and select the ContosoHR database, click Ctrl + O.
        1. In the Open File dialog, navigate to the tsql-scripts folder and select ListAllEmployees.sql.
        1. In Object Explorer, select the ContosoHR database and click Ctrl + O again.
        1. In the Open File dialog, navigate to the tsql-scripts folder and select QueryEvents.sql.
2. Prepare your browser.
    1. Open your browser.
    1. Point the browser to the demo application URL.
    1. Open a new tab and point to Azure Portal: https://portal.azure.com.
    1. Sign in to Azure if prompted.
    1. In the Search box in the Azure Portal, enter the name of your demo resource group and click Enter. In the search results, click on your resource group.

### Demos steps

1. Show the Contoso HR web app in the the browser. This application displays employee records and allows you filter employee records by salary or by a portion of the social security number (SSN). Move the salary slider and enter a couple of digits in the search box to filter by salary and SSN.
2. Switch to SSMS, click on the tab containing the ListAllEmployees.sql query and click F5 to execute the query. It shows the content of the database, the web application uses as a data store. Although you are a DBA of the database, you cannot see the plaintext data in the SSN and Salary columns, as those two columns are protected with Always Encrypted. 
3. Click on the tab containing the QueryXevents.sql query and click F5 to execute it. This query retrieves extended events from the Demo extended event session, configured in the ContosoHR database. Each extended event captures a query the web application has sent to the database.
4. Click on the link in the second column of the first row of the result set to see the extended event with the latest query from the application. 
    1. Review the query statement. Note that the query contains the WHERE clause with rich computations on encrypted columns: pattern matching using the LIKE predicate on the SSN column and the range comparison on the Salary column. The query also sorts records (the ORDER BY clause) by SSN or Salary.
    1. Scroll to the right, until you can see the value of the @SSNSearchPattern parameter. Note that the value of the parameter is encrypted – the client driver inside the web app transparently encrypts parameters corresponding to encrypted columns, before sending the query to the database. Not only does not the DBA have access to sensitive data in the database, but the DBA cannot see the plaintext values of query parameters used to process that data.