# Infrastructure: Stitches Azure Resources

This directory contains Infrastructure as Code (IaC) templates for provisioning Azure resources.

## Prerequisites

- **Azure CLI**: 2.50+ ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Azure Subscription**: With Owner or Contributor permissions
- **Bicep CLI**: Included with Azure CLI 2.20+ (`az bicep version`)

## Directory Structure

```text
infrastructure/
├── bicep/
│   ├── main.bicep           # Root template
│   ├── modules/             # Reusable resource definitions
│   │   ├── app-service-plan.bicep
│   │   ├── app-service.bicep
│   │   ├── sql-database.bicep
│   │   ├── blob-storage.bicep
│   │   ├── key-vault.bicep
│   │   ├── app-insights.bicep
│   │   └── cdn.bicep
│   └── parameters/          # Environment-specific values
│       ├── dev.parameters.json
│       ├── staging.parameters.json
│       └── prod.parameters.json
├── scripts/
│   ├── provision.sh         # Deploy Azure resources
│   ├── migrate.sh           # Run database migrations
│   └── smoke-test.sh        # Verify deployment health
└── README.md                 # This file
```

## Provisioning Azure Resources

### 1. Login to Azure

```bash
az login
az account set --subscription "<subscription-name>"
```

### 2. Create Resource Group

```bash
# For staging
az group create --name stitches-staging --location eastus

# For production
az group create --name stitches-prod --location eastus
```

### 3. Deploy Infrastructure

The provisioning script requires a SQL Server administrator password for security.

```bash
# Generate a secure password (or use your own)
SQL_PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 20)

# Deploy to staging
./scripts/provision.sh staging "${SQL_PASSWORD}"

# Deploy to production
./scripts/provision.sh prod "${SQL_PASSWORD}"
```

**Password Requirements**:
- At least 8 characters
- Contains uppercase and lowercase letters
- Contains numbers and special characters

**Important**: Save the password securely! It will be automatically stored in Key Vault as `SqlAdminPassword` and used to build the database connection string.

### 4. Verify Deployment

```bash
# List deployed resources
az resource list --resource-group stitches-staging --output table
```

## Manual Steps (Not Automatable via Bicep)

### Azure Cost Management Budget

Azure Cost Management budgets cannot be created via Bicep. Create manually:

```bash
# Create monthly budget with $500 threshold
az consumption budget create \
  --resource-group stitches-staging \
  --budget-name monthly-budget \
  --amount 500 \
  --time-grain Monthly \
  --start-date $(date +%Y-%m-01) \
  --end-date $(date -v+1y +%Y-%m-%d)
```

Or configure via Azure Portal:

1. Navigate to Cost Management + Billing
2. Select "Budgets" → "Add"
3. Set amount to $500/month
4. Configure email alerts at 80%, 100%, 120%

## Secrets Management

All secrets are stored in Azure Key Vault. The provisioning script automatically creates:

1. **Auto-Created by provision.sh**:
   - `SqlAdminPassword`: SQL Server administrator password (from CLI parameter)
   - `DatabaseConnectionString`: Built from SQL server FQDN and credentials

2. **Manual Setup Required**:

   ```bash
   # Generate and set JWT signing key
   JWT_KEY=$(openssl rand -base64 64)
   az keyvault secret set \
     --vault-name kv-stitches-staging \
     --name JwtSigningKey \
     --value "${JWT_KEY}"

   # Set OAuth client secret (will be needed for Feature 001)
   az keyvault secret set \
     --vault-name kv-stitches-staging \
     --name OAuthClientSecret \
     --value "<your-oauth-client-secret>"
   ```

3. **Verify Secrets**:

   ```bash
   az keyvault secret list --vault-name kv-stitches-staging --query "[].name" -o table
   ```

4. **Rotate Secrets**:
   - Update secret value in Key Vault
   - App Service automatically retrieves new value on next restart
   - See [Key Vault Access Runbook](../docs/runbooks/key-vault-access.md)

## CI/CD Pipeline Configuration

The GitHub Actions workflows require the following secrets to be configured in your repository:

### Required GitHub Secrets

1. **`AZURE_CREDENTIALS`** - Service Principal credentials for Azure deployment

   Create a service principal and configure the secret:

   ```bash
   # Create service principal
   az ad sp create-for-rbac \
     --name "stitches-github-actions" \
     --role contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/stitches-staging \
     --sdk-auth

   # Copy the JSON output to GitHub Settings → Secrets → Actions → New repository secret
   # Name: AZURE_CREDENTIALS
   ```

2. **`SQL_ADMIN_PASSWORD`** - SQL Server administrator password

   ```bash
   # Generate a secure password
   SQL_PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 20)
   
   # Add to GitHub Settings → Secrets → Actions → New repository secret
   # Name: SQL_ADMIN_PASSWORD
   # Value: <your-secure-password>
   ```

   ⚠️ **Important**: Use different passwords for staging and production. Consider using [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) to store environment-specific secrets (e.g., `SQL_ADMIN_PASSWORD_STAGING` and `SQL_ADMIN_PASSWORD_PROD`).

### Configure Secrets in GitHub

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each required secret listed above

For production deployments, consider using [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment) to store environment-specific secrets.

## Disaster Recovery

### Manual Deployment Procedure

If CI/CD pipeline is unavailable:

```bash
# 1. Build frontend
cd frontend && npm ci && npm run build

# 2. Publish backend
cd backend && dotnet publish -c Release -o ./publish

# 3. Deploy to App Service
az webapp deploy --resource-group stitches-staging \
  --name stitches-staging \
  --src-path ./publish \
  --type zip

# 4. Copy frontend to wwwroot
az webapp deploy --resource-group stitches-staging \
  --name stitches-staging \
  --src-path ../frontend/dist \
  --target-path /home/site/wwwroot/wwwroot
```

### Database Backup Restore

```bash
# List available backups
az sql db ltr-backup list --location eastus --server stitches-sql-prod

# Restore from backup
az sql db restore --dest-name stitches-restored \
  --resource-group stitches-prod \
  --server stitches-sql-prod \
  --source-database stitches \
  --deleted-time "2026-01-31T12:00:00Z"
```

## Runbooks

- [Deployment Failure](../docs/runbooks/deployment-failure.md)
- [Migration Rollback](../docs/runbooks/migration-rollback.md)
- [Key Vault Access Issues](../docs/runbooks/key-vault-access.md)

## Resource Configurations

### App Service Plan SKUs

| Environment | SKU | Instances | Notes |
|-------------|-----|-----------|-------|
| dev | B1 | 1 | Basic tier for development |
| staging | S1 | 1 | Standard tier for testing |
| prod | P1v2 | 2 | Premium for high availability |

### Storage Replication

| Environment | Replication | Notes |
|-------------|-------------|-------|
| dev/staging | LRS | Locally redundant, lower cost |
| prod | RA-GRS | Geo-redundant with read access |

### SQL Database Backup

| Environment | Backup Type | Notes |
|-------------|-------------|-------|
| dev/staging | Simple | Basic backup retention |
| prod | Zone-redundant | High availability backup |

## Alerts Configuration

All environments have Application Insights alerts configured:

| Metric | Threshold | Window | Severity |
|--------|-----------|--------|----------|
| Availability | < 99.5% | 5 min | Sev 1 |
| API Latency (p95) | > 500ms | 5 min | Sev 2 |
| Error Rate | > 1% | 5 min | Sev 2 |

Alert notifications are sent to configured action group (email/webhook).

---

**Last Updated**: 2026-01-31
