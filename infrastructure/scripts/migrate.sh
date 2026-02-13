#!/bin/bash
# Run database migrations against Azure SQL Database
# Usage: ./migrate.sh <environment>
# Example: ./migrate.sh staging

set -e

ENVIRONMENT=${1:-staging}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/../../backend"

echo "🗄️  Running database migrations for environment: ${ENVIRONMENT}"

# Get connection string from Key Vault
KEY_VAULT_NAME="kv-stitches-${ENVIRONMENT}"

echo "📦 Fetching connection string from Key Vault: ${KEY_VAULT_NAME}"
CONNECTION_STRING=$(az keyvault secret show \
    --vault-name "${KEY_VAULT_NAME}" \
    --name "DatabaseConnectionString" \
    --query "value" \
    --output tsv)

if [ -z "${CONNECTION_STRING}" ] || [ "${CONNECTION_STRING}" == "PLACEHOLDER_UPDATE_ME" ]; then
    echo "❌ Database connection string not configured in Key Vault"
    echo "   Please set the 'DatabaseConnectionString' secret with a valid connection string"
    exit 1
fi

echo "🔧 Running EF Core migrations..."
cd "${BACKEND_DIR}"

# Set connection string as environment variable
export ConnectionStrings__DefaultConnection="${CONNECTION_STRING}"

dotnet ef database update \
    --project src/Infrastructure \
    --startup-project src/Api \
    --no-build

echo ""
echo "✅ Database migrations completed successfully!"
