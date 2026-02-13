#!/bin/bash
# Provision Azure infrastructure for Stitches
# Usage: ./provision.sh <environment> <sql-admin-password>
# Example: ./provision.sh staging 'MySecureP@ssw0rd!'

set -e

ENVIRONMENT=${1:-staging}
SQL_ADMIN_PASSWORD=${2}
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

# Validate SQL admin password is provided
if [[ -z "${SQL_ADMIN_PASSWORD}" ]]; then
    echo "❌ SQL administrator password is required"
    echo "   Usage: ./provision.sh <environment> <sql-admin-password>"
    echo "   Example: ./provision.sh staging 'MySecureP@ssw0rd!'"
    echo ""
    echo "   Password requirements:"
    echo "   - At least 8 characters"
    echo "   - Contains uppercase and lowercase letters"
    echo "   - Contains numbers and special characters"
    exit 1
fi

# Validate password meets minimum Azure SQL requirements
# Azure SQL requires characters from at least 3 of these 4 categories:
# uppercase, lowercase, numbers, special characters
if [[ ${#SQL_ADMIN_PASSWORD} -lt 8 ]]; then
    echo "❌ Password must be at least 8 characters long"
    exit 1
fi

COMPLEXITY_COUNT=0
[[ "${SQL_ADMIN_PASSWORD}" =~ [A-Z] ]] && COMPLEXITY_COUNT=$((COMPLEXITY_COUNT + 1))
[[ "${SQL_ADMIN_PASSWORD}" =~ [a-z] ]] && COMPLEXITY_COUNT=$((COMPLEXITY_COUNT + 1))
[[ "${SQL_ADMIN_PASSWORD}" =~ [0-9] ]] && COMPLEXITY_COUNT=$((COMPLEXITY_COUNT + 1))
# Check for allowed special characters using grep (hyphen at end of character class)
echo "${SQL_ADMIN_PASSWORD}" | grep -q '[@#%^&*_+-]' && COMPLEXITY_COUNT=$((COMPLEXITY_COUNT + 1))

if [[ ${COMPLEXITY_COUNT} -lt 3 ]]; then
    echo "❌ Password must contain characters from at least 3 of these categories:"
    echo "   - Uppercase letters (A-Z)"
    echo "   - Lowercase letters (a-z)"
    echo "   - Numbers (0-9)"
    echo "   - Special characters (@#%^&*_+-)"
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
    --parameters sqlAdministratorPassword="${SQL_ADMIN_PASSWORD}" \
    --query "properties.outputs" \
    --output json)

echo "✅ Infrastructure provisioned successfully!"
echo ""
echo "📋 Deployment Outputs:"
echo "${DEPLOYMENT_OUTPUT}" | jq '.'

# Extract Key Vault information
KEY_VAULT_URL=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.keyVaultUrl.value')
KEY_VAULT_NAME=$(echo "${KEY_VAULT_URL}" | sed 's|https://||' | sed 's|.vault.azure.net/||')
SQL_SERVER_FQDN=$(echo "${DEPLOYMENT_OUTPUT}" | jq -r '.sqlServerFqdn.value')

# Store SQL admin password in Key Vault
echo ""
echo "🔐 Storing SQL administrator password in Key Vault: ${KEY_VAULT_NAME}"
az keyvault secret set \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "SqlAdminPassword" \
    --value "${SQL_ADMIN_PASSWORD}" \
    --output none

# Build and store database connection string
# WARNING: This connection string contains sensitive credentials.
# It should only be accessed by authorized services with appropriate Key Vault access policies.
SQL_CONNECTION_STRING="Server=${SQL_SERVER_FQDN};Database=db-stitches-${ENVIRONMENT};User Id=sqladmin;Password=${SQL_ADMIN_PASSWORD};Encrypt=True;TrustServerCertificate=False;"
az keyvault secret set \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "DatabaseConnectionString" \
    --value "${SQL_CONNECTION_STRING}" \
    --output none

echo ""
echo "✅ Provisioning complete!"
echo ""
echo "⚠️  IMPORTANT: Required secrets not yet configured"
echo "   The following secrets must be set in Key Vault before deployment:"
echo ""
echo "   1. JwtSigningKey - Generate a secure random key for JWT signing"
echo "      Example: openssl rand -base64 64"
echo "      Command: az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name JwtSigningKey --value '<your-key>'"
echo ""
echo "   2. OAuthClientSecret - Will be needed for Feature 001 (OAuth authentication)"
echo "      Command: az keyvault secret set --vault-name ${KEY_VAULT_NAME} --name OAuthClientSecret --value '<your-secret>'"
echo ""
echo "📝 Next steps:"
echo "   1. Set the required secrets listed above"
echo "   2. Run database migrations: ./migrate.sh ${ENVIRONMENT}"
echo "   3. Deploy application code"
echo "   4. Run smoke tests: ./smoke-test.sh ${ENVIRONMENT}"
echo ""
echo "⚠️  WARNING: Application deployment will fail if required secrets are not set!"
