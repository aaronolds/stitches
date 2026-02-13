// Main Bicep template for Stitches infrastructure
// Deploys all Azure resources for the specified environment

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Base name for all resources')
param baseName string = 'stitches'

@description('SQL Server administrator password')
@secure()
param sqlAdministratorPassword string

// Resource naming
var resourcePrefix = '${baseName}-${environment}'
var appServicePlanName = 'plan-${resourcePrefix}'
var appServiceName = 'app-${resourcePrefix}'
var sqlServerName = 'sql-${resourcePrefix}'
var sqlDatabaseName = 'db-${resourcePrefix}'
var storageAccountName = replace('st${baseName}${environment}', '-', '')
var keyVaultName = 'kv-${resourcePrefix}'
var appInsightsName = 'ai-${resourcePrefix}'
var cdnProfileName = 'cdn-${resourcePrefix}'

// Tier configurations per environment
var appServiceSku = environment == 'prod' ? 'P1v2' : (environment == 'staging' ? 'S1' : 'B1')
var appServiceCapacity = environment == 'prod' ? 2 : 1
var storageReplication = environment == 'prod' ? 'Standard_RAGRS' : 'Standard_LRS'
var sqlDbBackupType = environment == 'prod' ? 'Zone' : 'Local'

// App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    sku: appServiceSku
    capacity: appServiceCapacity
  }
}

// Key Vault (deploy before App Service to get reference)
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    name: keyVaultName
    location: location
  }
}

// App Service
module appService 'modules/app-service.bicep' = {
  name: 'appService'
  params: {
    name: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// SQL Database
module sqlDatabase 'modules/sql-database.bicep' = {
  name: 'sqlDatabase'
  params: {
    serverName: sqlServerName
    databaseName: sqlDatabaseName
    location: location
    backupRedundancy: sqlDbBackupType
    administratorLoginPassword: sqlAdministratorPassword
  }
}

// Blob Storage
module blobStorage 'modules/blob-storage.bicep' = {
  name: 'blobStorage'
  params: {
    name: storageAccountName
    location: location
    sku: storageReplication
  }
}

// Application Insights
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
  }
}

// CDN (production only)
module cdn 'modules/cdn.bicep' = if (environment == 'prod') {
  name: 'cdn'
  params: {
    profileName: cdnProfileName
    location: location
    originHostName: appService.outputs.defaultHostName
  }
}

// Grant App Service access to Key Vault
module keyVaultAccess 'modules/key-vault-access.bicep' = {
  name: 'keyVaultAccess'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// Outputs
output appServiceUrl string = 'https://${appService.outputs.defaultHostName}'
output keyVaultUrl string = keyVault.outputs.uri
output appInsightsConnectionString string = appInsights.outputs.connectionString
output sqlServerFqdn string = sqlDatabase.outputs.serverFqdn
output storageAccountName string = blobStorage.outputs.name
