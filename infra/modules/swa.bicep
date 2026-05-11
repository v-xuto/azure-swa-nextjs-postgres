@description('Name of the Static Web App')
param name string

@description('Location for the Static Web App')
param location string

@description('Tags for the resource')
param tags object = {}

@description('SKU for the Static Web App')
@allowed([
  'Standard'
])
param sku string = 'Standard'

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: name
  location: location
  tags: union(tags, { 'azd-service-name': 'web' })
  sku: {
    name: sku
    tier: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
  }
}

output name string = staticWebApp.name
output defaultHostname string = staticWebApp.properties.defaultHostname
output id string = staticWebApp.id
output principalId string = staticWebApp.identity.principalId
