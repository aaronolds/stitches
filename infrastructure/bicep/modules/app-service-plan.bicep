// App Service Plan module

@description('Name of the App Service Plan')
param name string

@description('Azure region')
param location string

@description('SKU name (B1, S1, P1v2, etc.)')
param sku string

@description('Number of instances')
param capacity int

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  sku: {
    name: sku
    capacity: capacity
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
