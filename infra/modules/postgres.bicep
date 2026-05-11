@description('Name of the PostgreSQL Flexible Server')
param name string

@description('Location for the PostgreSQL server')
param location string

@description('Tags for the resource')
param tags object = {}

@description('Administrator login name')
param administratorLogin string

@secure()
@description('Administrator login password')
param administratorLoginPassword string

@description('SKU name for the PostgreSQL server')
param skuName string = 'Standard_B1ms'

@description('SKU tier for the PostgreSQL server')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Burstable'

@description('Storage size in GB')
param storageSizeGB int = 32

@description('PostgreSQL version')
param version string = '16'

@description('Name of the database to create')
param databaseName string

@description('Additional firewall rules')
param firewallRules array = []

@description('Object ID of the Entra ID administrator (leave empty to skip)')
param entraAdminObjectId string = ''

@description('Display name of the Entra ID administrator')
param entraAdminName string = ''

@description('Type of the Entra ID administrator principal')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param entraAdminType string = 'User'

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: server
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: server
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

@batchSize(1)
resource customFirewallRules 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = [for rule in firewallRules: {
  parent: server
  name: rule.name
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

resource entraAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2024-08-01' = if (!empty(entraAdminObjectId)) {
  parent: server
  name: entraAdminObjectId
  properties: {
    principalType: entraAdminType
    principalName: entraAdminName
    tenantId: subscription().tenantId
  }
  dependsOn: [database]
}

output fqdn string = server.properties.fullyQualifiedDomainName
output name string = server.name
output databaseName string = databaseName
output id string = server.id
