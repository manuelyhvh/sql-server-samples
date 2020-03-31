#Requires -Modules @{ ModuleName="AzureRM.Sql"; ModuleVersion="4.12.1" }
#Data Sync OMS Integration Runbook

#To use this script Change all the strings below to reflect your information. 

#Information for Sync Group 1
#If you want to use all the sync groups in your subscription keep the $DS_xxxx fields empty. 
#If you want to use all sync groups in a Resource Group define the $DS_ResourceGroupName. 
#If you want to use all sync groups in a Server define $DS_ResourceGroupName and $DS_ServerName.
#If you want to use all sync groups in a Database define $DS_ResourceGroupName, $DS_ServerName and $DS_DatabaseName.
#If you want to use a specific sync group define $DS_ResourceGroupName, $DS_ServerName, $DS_DatabaseName and $DS_SyncGroupName.

$SubscriptionId = "SubscriptionId" 
$DS_ResourceGroupName = ""
$DS_ServerName =  "" 
$DS_DatabaseName = "" 
$DS_SyncGroupName = "" 

$AC_ResourceGroupName = "ResourceGroupName"
$AC_AccountName = "AutomationAccountName"
$AC_LastUpdatedTimeVariableName = "DataSyncLogLastUpdatedTime"

# Replace with your OMS Workspace ID
$CustomerId = "OMSCustomerID"  

# Replace with your OMS Primary Key
$SharedKey = "SharedKey"

# Specify the name of the record type that you'll be creating
$LogType = "DataSyncLog"

# Specify a field with the created time for the records
$TimeStampField = "DateValue"

#Specify the interval of how often you want to send data to oms
#You can use -hours, -minutes or -days, use a negative number
#$interval = New-TimeSpan -hours -1


#Connect to Azure
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Create the function to create the authorization signature
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}


# Create the function to create and post the request
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -fileName $fileName `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}


#Get Log Data
select-azurermsubscription -SubscriptionId $SubscriptionId
$endtime =[System.DateTime]::UtcNow
$StartTime = Get-AzureRmAutomationVariable -ResourceGroupName $AC_ResourceGroupName `
                                        –AutomationAccountName $AC_AccountName `
                                        -Name $AC_LastUpdatedTimeVariableName | Select -ExpandProperty Value


#Get Log
Write-Output "Getting Data Sync Log from $StartTime to $EndTime"

if ($DS_ResourceGroupName -eq "")
{
    $ResourceGroupName = Get-AzureRmResourceGroup | select -ExpandProperty ResourceGroupName
}
else
{
    $ResourceGroupName = $DS_ResourceGroupName
}

foreach ($ResourceGroup in $ResourceGroupName)
{
    if ($DS_ServerName -eq "")
    {
        $ServerName = Get-AzureRmSqlServer -ResourceGroupName $ResourceGroup | select -ExpandProperty ServerName
    }
    else
    {
        $ServerName = $DS_ServerName
    }

    foreach ($Server in $ServerName)
    {
        if ($DS_DatabaseName -eq "")
        {
            $DatabaseName = Get-AzureRmSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $Server | select -ExpandProperty DatabaseName
        }
        else
        {
            $DatabaseName = $DS_DatabaseName
        }

        foreach ($Database in $DatabaseName)
        {
            if ($Database -eq "master")
            {
                continue;
            }

            if ($DS_SyncGroupName -eq "")
            {
                $SyncGroupName = Get-AzureRmSqlSyncGroup -ResourceGroupName $ResourceGroup -ServerName $Server -DatabaseName $Database | select -ExpandProperty SyncGroupName
            }
            else
            {
                $SyncGroupName = $DS_SyncGroupName
            }

            foreach ($SyncGroup in $SyncGroupName)
            {
                $Logs = Get-AzureRmSqlSyncGroupLog -ResourceGroupName $ResourceGroup `
                                                  -ServerName $Server `
                                                  -DatabaseName $Database `
                                                  -SyncGroupName $SyncGroup `
                                                  -starttime $StartTime `
                                                  -endtime $EndTime;

                if ($Logs.Length -gt 0)
                {
                foreach ($Log in $Logs)
                {
                    $Log | Add-Member -Name "SubscriptionId" -Value $SubscriptionId -MemberType NoteProperty
                    $Log | Add-Member -Name "ResourceGroupName" -Value $ResourceGroup -MemberType NoteProperty
                    $Log | Add-Member -Name "ServerName" -Value $Server -MemberType NoteProperty
                    $Log | Add-Member -Name "HubDatabaseName" -Value $Database -MemberType NoteProperty
                    $Log | Add-Member -Name "SyncGroupName" -Value $SyncGroup -MemberType NoteProperty 

                    #Filter out Successes to Reduce Data Volume to OMS
                    #Include the 5 commented out line below to enable the filter
                    #For($i=0; $i -lt $Log.Length; $i++ ) {
                    #    if($Log[$i].LogLevel -eq "Success") {
                    #      $Log[$i] =""      
                    #    }
                    # }



                }


                $json = ConvertTo-JSON $logs



                $result = Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
                if ($result -eq 200) 
                {
                    Write-Host "Success"
                }
                if ($result -ne 200) 
               {
                   throw 
@"
                    Posting to OMS Failed                         
                    Runbook Name: DataSyncOMSIntegration                         
"@
                }
                }
            }
        }
    }
}



Set-AzureRmAutomationVariable -ResourceGroupName $AC_ResourceGroupName `
                          –AutomationAccountName $AC_AccountName `
                          -Name $AC_LastUpdatedTimeVariableName `
                          -Value $EndTime `
                          -Encrypted $False
