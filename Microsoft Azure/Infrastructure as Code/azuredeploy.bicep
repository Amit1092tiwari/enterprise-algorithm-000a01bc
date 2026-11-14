// ====================================================================
// ENTERPRISE AZURE DATA PLATFORM DEPLOYMENT (BICEP)
// Author: Amitkumar Tiwari
// Repository: https://github.com/Amit1092tiwari/Advancesqlpuzzle
// ====================================================================

@description('Deployment location')
param location string = resourceGroup().location

@description('Project short prefix')
param projectName string = 'sqldemo'

@description('Environment tag')
param environment string = 'dev'

@description('Administrator login for Azure SQL Server')
param sqlAdminLogin string = 'sqladmin'

@description('Administrator password for Azure SQL Server')
@secure()
param sqlAdminPassword string

var uniqueSuffix = uniqueString(resourceGroup().id)
var storageAccountName = 'st${projectName}${uniqueSuffix}'
var sqlServerName = 'sql-${projectName}-${uniqueSuffix}'
var sqlDbName = 'sqldb-${projectName}'
var adfName = 'adf-${projectName}-${uniqueSuffix}'
var databricksName = 'dbw-${projectName}-${environment}'

// 1. Storage Account with ADLS Gen2 Hierarchical Namespace
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource containerRaw 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'raw'
}

resource containerCurated 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'curated'
}

resource containerMetadata 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'metadata'
}

// 2. Azure SQL Database Server & DB
resource sqlServer 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
  }
}

resource sqlFirewall 'Microsoft.Sql/servers/firewallRules@2022-11-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-11-01-preview' = {
  parent: sqlServer
  name: sqlDbName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

// 3. Azure Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// 4. Azure Databricks Workspace
resource databricksWorkspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: databricksName
  location: location
  sku: {
    name: 'standard'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', 'rg-${databricksName}-managed')
  }
}

output storageAccountName string = storageAccount.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output dataFactoryName string = dataFactory.name
output databricksWorkspaceUrl string = databricksWorkspace.properties.workspaceUrl
