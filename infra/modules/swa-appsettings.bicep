@description('Name of the existing Static Web App')
param swaName string

@description('Application Insights connection string')
param appInsightsConnectionString string

@secure()
@description('The PostgreSQL connection string to set as DATABASE_URL')
param databaseUrl string

resource swa 'Microsoft.Web/staticSites@2023-12-01' existing = {
  name: swaName
}

resource appSettings 'Microsoft.Web/staticSites/config@2023-12-01' = {
  parent: swa
  name: 'appsettings'
  properties: {
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
    DATABASE_URL: databaseUrl
  }
}
