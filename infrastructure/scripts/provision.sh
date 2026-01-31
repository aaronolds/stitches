#!/bin/bash
# Provision Azure infrastructure for Stitches
# Usage: ./provision.sh <environment>
# Example: ./provision.sh staging

set -e

ENVIRONMENT=${1:-staging}
RESOURCE_GROUP="stitches-${ENVIRONMENT}"
LOCATION="eastus"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="${SCRIPT_DIR}/../bicep"

echo "🚀 Provisioning Stitches infrastructure for environment: ${ENVIRONMENT}"

# Validate environment
if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Invalid environment: ${ENVIRONMENT}"
    echo "   Valid values: dev, staging, prod"
    exit 1
fi

# Check Azure CLI login
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

echo "📦 Creating resource group: ${RESOURCE_GROUP}"
az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --output none

echo "🔧 Deploying Bicep templates..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "${RESOURCE_GROUP}" \
    --template-file "${BICEP_DIR}/main.bicep" \
    --parameters "${BICEP_DIR}/parameters/${ENVIRONMENT}.parameters.json" \
    --query "properties.outputs" \
    --output json)

echo "✅ Infrastructure provisioned successfully!"
echo ""
echo "📋 Deployment Outputs:"
echo "${DEPLOYMENT_OUTPUT}" | jq '.'

# Extract Key Vault name and create placeholder secrets
KEY_VAULT_URL=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.keyVaultUrl.value')
KEY_VAULT_NAME=$(echo "${KEY_VAULT_URL}" | sed 's|https://||' | sed 's|.vault.azure.net/||')

echo ""
echo "🔐 Creating placeholder secrets in Key Vault: ${KEY_VAULT_NAME}"

# Create placeholder secrets (values should be updated manually or via secure pipeline)
az keyvault secret set \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "DatabaseConnectionString" \
    --value "PLACEHOLDER_UPDATE_ME" \
    --output none 2>/dev/null || echo "   DatabaseConnectionString already exists"

az keyvault secret set \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "JwtSigningKey" \
    --value "PLACEHOLDER_UPDATE_ME" \
    --output none 2>/dev/null || echo "   JwtSigningKey already exists"

az keyvault secret set \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "OAuthClientSecret" \
    --value "PLACEHOLDER_FOR_FEATURE_1" \
    --output none 2>/dev/null || echo "   OAuthClientSecret already exists"

echo ""
echo "✅ Provisioning complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Update secrets in Key Vault with actual values"
echo "   2. Run database migrations: ./migrate.sh ${ENVIRONMENT}"
echo "   3. Deploy application code"
echo "   4. Run smoke tests: ./smoke-test.sh ${ENVIRONMENT}"
