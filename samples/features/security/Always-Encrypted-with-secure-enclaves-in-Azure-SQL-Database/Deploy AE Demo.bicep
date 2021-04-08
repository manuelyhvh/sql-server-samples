////////////////////
//Define parameter//
////////////////////

param objectId string
@description('Location for all resources.')
param location string = resourceGroup().location

@description('Project Name')
param projectname string = 'eaeaedemo'

param currentTime string = utcNow('u')

param adminUsername string
param adminPassword string
param AADSQLAdmin string 
param clientIP string 

//Make the subscription Contributor of the resource group
resource AssignContributorToUser_Resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(resourceGroup().id),currentTime)
  scope: any(resourceGroup().id)
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: objectId
    principalType: 'User'
  }
}

///////////////////////////////////////////////////
//Create a storage account with a database bacpac//
//////////////////////////////////////////////////

// Create a storage account
@description('Storage Account type')
param storageAccountType string = 'Standard_LRS'
var storageAccountName_var = '${projectname}storage'

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {}
}

output storageoutput string = storageAccountResource.name

resource storageAccountname 'Microsoft.Storage/storageAccounts/blobServices@2020-08-01-preview' = {
  name: '${storageAccountResource.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource Containerbacpacfiles 'Microsoft.Storage/storageAccounts/blobServices/containers@2020-08-01-preview' = {
  name: '${storageAccountname.name}/bacpacfiles'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccountResource
  ]
}

////////////////////////////
//Create a database server//
////////////////////////////

// Create the server

var SQLServerName_var = '${projectname}server'
resource Server_Name_resource 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: SQLServerName_var
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    //version: 'string' //optional
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

//Allow Azure services and resources to access this server
resource Server_Name_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2015-05-01-preview' = {
  name: '${Server_Name_resource.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

//Allow Client IP to access this server
resource Server_Name_AllowClientIP 'Microsoft.Sql/servers/firewallRules@2015-05-01-preview' = {
  name: '${Server_Name_resource.name}/AllowClientIP'
  properties: {
    endIpAddress: clientIP
    startIpAddress: clientIP
  }
}

//Make yourself an administrator, so that you can connect with universal authentication
resource Server_Name_activeDirectory 'Microsoft.Sql/servers/administrators@2019-06-01-preview' = {
  name: '${Server_Name_resource.name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: AADSQLAdmin
    sid: reference(resourceId('Microsoft.Sql/servers', '${projectname}server'), '2019-06-01-preview', 'Full').identity.principalId
    //tenantId: AAD_TenantId //optional
  }
}

///////////////////////////////////////////////
//Import and configure the ContosoHR database//
///////////////////////////////////////////////
resource Database_Resource 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${Server_Name_resource.name}/ContosoHR'
  location: location
  tags: {}
  sku: {
    name: 'GP_DC_2'
    tier: 'GeneralPurpose'
    
  }
  properties: {}
}

//Import the BACPAC
resource ImportBACPAC_resource 'Microsoft.Sql/servers/databases/extensions@2014-04-01' = {
  name: '${Database_Resource.name}/extensions'
  properties: {
    storageKeyType: 'SharedAccessKey'
    storageKey: '?'
    storageUri: 'https://easetupfiles.blob.core.windows.net/setup/contosohr.bacpac'
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    authenticationType: 'SQL'
    operationMode: 'Import'
  }
}

//Create ManagedIdenty to perform any Azure-specific actions in the deployment scripts
resource ManagedIdentity_Resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'EAEDemoManagedIdentity'
  tags: {}
  location: location
}

var uamiId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', '${ManagedIdentity_Resource.name}')

//Add the Managed Identity to the Contributor Role
resource AssignContributor_Resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  //name: guid(resourceGroup().id,currentTime)
  name: guid(uniqueString(resourceGroup().id),dateTimeAdd(currentTime,'PT1S'))
  scope: any(resourceGroup().id)
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: ManagedIdentity_Resource.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    ManagedIdentity_Resource
  ]
}

/////////////////////////////////////
//Configure an attestation provider//
/////////////////////////////////////

//Create the attestation provider
resource attestationProviderName_resource 'Microsoft.Attestation/attestationProviders@2020-10-01' = {
  name: '${projectname}attest'
  location: location
  properties: {}
}

//Upload the recommended attestation policy for SGX enclaves
//!!!!Not working yet!!!

// resource UploadAttestinationPolicy 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'UploadAttestinationPolicy'
//   location: location
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${uamiId}': {}
//     }
//   }
//   kind: 'AzurePowerShell'
//     properties: {
//     azPowerShellVersion: '5.0'
//     // storageAccountSettings: {
//     //   storageAccountName: storageAccountResource.name
//     //   storageAccountKey: listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value
//     // }
//     //scriptContent: '\r\n az storage blob copy start --account-key ${listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value} --account-name ${storageAccountResource.name} --destination-blob contosohr.bacpac --destination-container bacpacfiles --source-uri https://easetupfiles.blob.core.windows.net/setup/contosohr.bacpac'
//     //scriptContent: 'az config set extension.use_dynamic_install=yes_without_prompt \r\n az attestation policy set --name ${projectname}attest --resource-group ${resourceGroup().name} --attestation-type SGX-IntelSDK --new-attestation-policy-file "{https://easetupfiles.blob.core.windows.net/setup/policy.txt}"'
//     scriptContent: 'Import-Module "Az.Attestation" -MinimumVersion "0.1.8" \r\n $blobContext=New-AzstorageContext -StorageAccountName "easetupfiles" -Anonymous -Protocol "https" \r\n $policyFile=Get-AzStorageBlob -Blob policy.txt -Container setup -Context $blobContext \r\n $Policy = $policyFile.ICloudBlob.DownloadText() \r\n Set-AzAttestationPolicy -Name ${projectname}attest -ResourceGroupName ${resourceGroup().name} -Tee SgxEnclave -Policy $policy -PolicyFormat Text'
//     cleanupPreference: 'OnSuccess'
//     retentionInterval: 'P1D'
//     forceUpdateTag: currentTime // ensures script will run every time
//   }
// }

//Grant the database server access to the attestation provider
resource AssignAttestationReader_Resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id,currentTime)
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/fd1bd22b-8476-40bc-a0bc-69b95687b9f3'
    principalId: Server_Name_resource.identity.principalId
  }
}

/////////////////////////////////////
//Configure the web application    //
/////////////////////////////////////

//Create an App Service plan in Free tier
resource WebAppServicePlan_Resource 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: '${projectname}plan'
 location: location
 properties: {}
  sku: {
    name: 'F1'
    tier: 'Free'
  }
}

//Create the App Service
resource WebApp_Resource 'Microsoft.Web/sites@2020-09-01' = {
  name: '${projectname}app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: WebAppServicePlan_Resource.id
       
 }
}

//Add the connection string to the Azure SQL Database
resource WebAppConnectionString_Resource 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${WebApp_Resource.name}/connectionstrings'
  properties: {
    ContosoHRDatabase: {
      value: 'Server=tcp:${Server_Name_resource.name}.database.windows.net;Database=ContosoHR;Column Encryption Setting=Enabled; Attestation Protocol = AAS; Enclave Attestation Url=${attestationProviderName_resource.properties.attestUri}/attest/SgxEnclave; Authentication=Active Directory Managed Identity'
      type: 'SQLAzure'
    }
  } 
}

//Deploy the Web Application
resource DeployWebApp 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'DeployWebApp'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${uamiId}': {}
    }
  }
  kind: 'AzurePowerShell'
    properties: {
    azPowerShellVersion: '5.0'
    storageAccountSettings: {
       storageAccountName: storageAccountResource.name
       storageAccountKey: listKeys(storageAccountResource.id, storageAccountResource.apiVersion).keys[0].value
    }
    scriptContent: '$PropertiesObject = @{repoUrl = "https://github.com/Pietervanhove/AEDemo.git"; branch = "master"; isManualIntegration = "true";} \r\n Set-AzResource -Properties $PropertiesObject -ResourceGroupName ${resourceGroup().name} -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName ${WebApp_Resource.name}/web -ApiVersion 2015-08-01 -Force'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: currentTime // ensures script will run every time
  }
}


////////////////////////////////////
//Create and configure a key vault//
////////////////////////////////////

//Create a key vault and Assign key permissions to yourself, so that you manage the keys
resource KeyVault_Resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: '${projectname}vault'
  location: location
  tags: {}
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: false
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          keys: [
            'unwrapKey'
            'wrapKey'
            'verify'
            'sign'
            'get'
            'list'
            'create'
            'delete'
            'purge'
          ]
        }
      }
    ]
  }
}

//Assign key permissions to the web app 
resource KeyVaultWebAppAccessPolicy_Resource 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: any('${KeyVault_Resource.name}/add')
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        //objectId: reference(resourceId('Microsoft.Web/sites', '${projectname}app'), '2020-12-01', 'Full').resourceId
        objectId: WebApp_Resource.identity.principalId
        permissions: {
          keys: [
            'unwrapKey'
            'wrapKey'
            'verify'
            'sign'
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

//Create a Key
resource Key_Resource 'Microsoft.KeyVault/vaults/keys@2019-09-01' = {
  name: '${KeyVault_Resource.name}/CMK'
  tags: {}
  properties: {
    kty: 'RSA'
  }
  dependsOn: [
    KeyVault_Resource
  ]
}

//Post Deploy Script not working 
//The term 'New-SqlColumnEncryptionSettings' is not recognized as a name of a cmdlet, function, script file, or executable program.
