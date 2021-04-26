///////////////////////
// Define parameters //
///////////////////////

@description('The project name. The names of all resources will be derived from the project name.')
param projectName string

@description('The object id of the user running the deployment.')
param userObjectId string

@description('The username of the user running the deployment.')
param userName string 

@description('The username of the Azure SQL database server administrator for SQL authentication.')
param sqlAdminUserName string

@description('The password of the Azure SQL database server administrator for SQL authentication.')
param sqlAdminPassword string

@description('The IP address the user will connect from to the Azure SQL database server.')
param clientIP string 

@description('The location (the Azure region) for all resources.')
param location string = resourceGroup().location

@description('The current time.')
param currentTime string = utcNow('u')

////////////////////////////////////////////
// Create and configure a database server //
////////////////////////////////////////////

// Create the server
var SQLServerName_var = '${projectName}server'
resource Server_Name_resource 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: SQLServerName_var
  location: location
  tags: {}
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: sqlAdminUserName
    administratorLoginPassword: sqlAdminPassword
    //version: 'string' //optional
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Allow Azure services and resources to access this server
resource Server_Name_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2015-05-01-preview' = {
  name: '${Server_Name_resource.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

// Allow Client IP to access this server
resource Server_Name_AllowClientIP 'Microsoft.Sql/servers/firewallRules@2015-05-01-preview' = {
  name: '${Server_Name_resource.name}/AllowClientIP'
  properties: {
    endIpAddress: clientIP
    startIpAddress: clientIP
  }
}

// Make the user an Azure AD administrator for the server, so that the user can connect with universal authentication
resource Server_Name_activeDirectory 'Microsoft.Sql/servers/administrators@2019-06-01-preview' = {
  name: '${Server_Name_resource.name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: userName
    //sid: reference(resourceId('Microsoft.Sql/servers', '${projectName}server'), '2019-06-01-preview', 'Full').identity.principalId
    sid: userObjectId
    //tenantId: AAD_TenantId //optional
  }
}

//////////////////////////////////////////////////////////////////////////////
// Create the ContosoHR database using the DC-series hardware configuration //
//////////////////////////////////////////////////////////////////////////////

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

///////////////////////////////////////
// Configure an attestation provider //
///////////////////////////////////////

// Create the attestation provider
resource attestationProviderName_resource 'Microsoft.Attestation/attestationProviders@2020-10-01' = {
  name: '${projectName}attest'
  location: location
  properties: {}
}

// Grant the database server access to the attestation provider
resource AssignAttestationReader_Resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id,currentTime)
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/fd1bd22b-8476-40bc-a0bc-69b95687b9f3'
    principalId: Server_Name_resource.identity.principalId
  }
}

///////////////////////////////////
// Configure the web application //
///////////////////////////////////

// Create a managed identity for the web app deployment
resource ManagedIdentity_Resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${projectName}identity'
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

// Create an App Service plan in Free tier
resource WebAppServicePlan_Resource 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: '${projectName}plan'
 location: location
 properties: {}
  sku: {
    name: 'F1'
    tier: 'Free'
  }
}

// Create the App Service
resource WebApp_Resource 'Microsoft.Web/sites@2020-09-01' = {
  name: '${projectName}app'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: WebAppServicePlan_Resource.id    
 }
}

// Set the database connection string for the application
resource WebAppConnectionString_Resource 'Microsoft.Web/sites/config@2020-09-01' = {
  name: '${WebApp_Resource.name}/connectionstrings'
  properties: {
    ContosoHRDatabase: {
      value: 'Server=tcp:${Server_Name_resource.name}.database.windows.net;Database=ContosoHR;Column Encryption Setting=Enabled; Attestation Protocol = AAS; Enclave Attestation Url=${attestationProviderName_resource.properties.attestUri}/attest/SgxEnclave; Authentication=Active Directory Managed Identity'
      type: 'SQLAzure'
    }
  } 
}

// Deploy the application
resource DeployWebApp 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${projectName}script'
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
    scriptContent: '$PropertiesObject = @{repoUrl = "https://github.com/Pietervanhove/AEDemo.git"; branch = "master"; isManualIntegration = "true";} \r\n Set-AzResource -Properties $PropertiesObject -ResourceGroupName ${resourceGroup().name} -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName ${WebApp_Resource.name}/web -ApiVersion 2015-08-01 -Force'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: currentTime // ensures script will run every time
  }
}

//////////////////////////////////////
// Create and configure a key vault //
//////////////////////////////////////

// Create a key vault and assign key permissions to the user, so that the user can manage the keys
resource KeyVault_Resource 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: '${projectName}vault'
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
        objectId: userObjectId
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

// Assign key permissions to the web app 
resource KeyVaultWebAppAccessPolicy_Resource 'Microsoft.KeyVault/vaults/accessPolicies@2019-09-01' = {
  name: any('${KeyVault_Resource.name}/add')
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        // objectId: reference(resourceId('Microsoft.Web/sites', '${projectName}app'), '2020-12-01', 'Full').resourceId
        objectId: WebApp_Resource.identity.principalId
        permissions: {
          keys: [
            'unwrapKey'
            'verify'
            'get'
          ]
        }
      }
    ]
  }
}

// Create a key
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
