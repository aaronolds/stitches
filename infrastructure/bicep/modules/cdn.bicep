// CDN module

@description('CDN Profile name')
param profileName string

@description('Azure region')
param location string

@description('Origin hostname (App Service)')
param originHostName string

resource cdnProfile 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: profileName
  location: location
  sku: {
    name: 'Standard_Microsoft'
  }
}

resource cdnEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-07-01-preview' = {
  parent: cdnProfile
  name: '${profileName}-endpoint'
  location: location
  properties: {
    originHostHeader: originHostName
    isHttpAllowed: false
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    optimizationType: 'GeneralWebDelivery'
    origins: [
      {
        name: 'appServiceOrigin'
        properties: {
          hostName: originHostName
          httpPort: 80
          httpsPort: 443
          priority: 1
          weight: 1000
          enabled: true
        }
      }
    ]
  }
}

output endpointHostName string = cdnEndpoint.properties.hostName
output profileName string = cdnProfile.name
