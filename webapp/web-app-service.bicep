param skuName string = 'S1'
param skuCapacity int = 1
param location string = resourceGroup().location
param appServicePlanName string = 'gmcappserv010'
param webAppName string = 'gmcwebapp010'
param appInsightsName string = 'gmcinsithsapp010'
param logAnalyticsName string = 'gmclogapp010'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}

resource appService 'Microsoft.Web/sites@2020-12-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
  }
}

resource appServiceLogging 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${appService.name}/logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warnig'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enable: true
      }
    }
    failRequestsTracing: {
      enable: true
    }
    detailedErrorMessages: {
      enable: true
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
    retentionInDays: 7
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: location
  kind: 'string'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource appServiceSiteExtension 'Microsoft.Web/sites/siteextensions@2020-12-01' = {
  name: '${appService.name}/Microsoft.ApplicationInsights.AzureWebsites'
  dependsOn: [
    appInsights
  ]
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${appService.name}/appSettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
  }
  dependsOn: [
    appInsights
    appServiceSiteExtension
  ]
}
