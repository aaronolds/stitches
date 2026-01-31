// Key Vault Access Policy module
// Grants App Service managed identity access to Key Vault secrets

@description('Key Vault name')
param keyVaultName string

@description('Principal ID to grant access to')
param principalId string

// Use RBAC instead of access policies (recommended)
resource keyVaultSecretUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultName, principalId, 'Key Vault Secrets User')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
