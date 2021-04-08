######################################################################
# Request parameters to the user that are needed for the deployment
######################################################################

$subscriptionName = Read-Host -Prompt "Enter your subscription name"
$projectName = Read-Host -Prompt "Enter a project name that is used to generate resource names"
$location = Read-Host -Prompt "Enter a region where you want to deploy the demo environment"
$upn = Read-Host -Prompt "Enter your email address used to sign in to Azure"
$adminUsername = Read-Host -Prompt "Enter the SQL Admin Username"
$adminPassword = Read-Host -Prompt "Enter the SQL Admin Password"

$adUserId = (az ad user show --id $upn --query objectId)
$clientIP = (Invoke-WebRequest ifconfig.me/ip).Content.Trim()
$bicepFile = "Deploy AE Demo.bicep"
$projectName = $projectName.ToLower()

######################################################################
# Sign in to Azure
######################################################################

Connect-AzAccount
$context = Set-AzContext -Subscription $subscriptionName

######################################################################
# Create a resource group
######################################################################
$resourceGroupName = "${projectName}"
New-AzResourceGroup -Name $resourceGroupName -Location $location

######################################################################
# Deploy the resources for the demo environment
######################################################################
az deployment group create --name DeployAEWithEnclavesDemo --template-file $bicepFile --resource-group $resourceGroupName --parameters objectId=$adUserId projectname=$projectName adminUsername=$adminUsername adminPassword=$adminPassword AADSQLAdmin=$upn clientIP=$clientIP


