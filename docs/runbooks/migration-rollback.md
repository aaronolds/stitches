# Migration Rollback Runbook

This runbook provides steps to revert Entity Framework Core database migrations.

## When to Use

- Migration failed during deployment
- Database schema issue discovered after deployment
- Need to roll back to previous database state

## Prerequisites

- .NET 10 SDK installed
- Azure CLI installed and logged in
- Access to Key Vault secrets

## Quick Rollback

### 1. Get Current Migration Status

```bash
cd backend

# List all migrations
dotnet ef migrations list --project src/Infrastructure --startup-project src/Api
```

### 2. Identify Target Migration

Find the migration you want to roll back TO (the last known good state).

Example output:
```
20260131000000_InitialCreate
20260131120000_AddUserTable     <- Current (problematic)
```

To roll back AddUserTable, target: `20260131000000_InitialCreate`

### 3. Roll Back (Local Development)

```bash
# Roll back to specific migration
dotnet ef database update 20260131000000_InitialCreate \
    --project src/Infrastructure \
    --startup-project src/Api
```

### 4. Roll Back (Staging/Production)

**Warning**: Production rollbacks require careful coordination.

```bash
# Get connection string from Key Vault
KEY_VAULT_NAME="kv-stitches-staging"  # or kv-stitches-prod
CONNECTION_STRING=$(az keyvault secret show \
    --vault-name $KEY_VAULT_NAME \
    --name DatabaseConnectionString \
    --query value -o tsv)

# Roll back with Azure SQL connection
ConnectionStrings__DefaultConnection="$CONNECTION_STRING" \
    dotnet ef database update 20260131000000_InitialCreate \
    --project src/Infrastructure \
    --startup-project src/Api
```

## Full Rollback Steps

### Step 1: Stop the Application (Optional)

For major rollbacks, stop the application to prevent conflicts:

```bash
az webapp stop --resource-group stitches-staging --name app-stitches-staging
```

### Step 2: Backup Current State

Create a database backup before rollback:

```bash
# Create point-in-time backup (Azure SQL)
az sql db export \
    --resource-group stitches-staging \
    --server sql-stitches-staging \
    --name db-stitches-staging \
    --admin-user sqladmin \
    --admin-password "<password>" \
    --storage-key-type SharedAccessKey \
    --storage-key "<storage-account-key>" \
    --storage-uri "https://ststitchesstaging.blob.core.windows.net/backups/backup-$(date +%Y%m%d-%H%M%S).bacpac"
```

### Step 3: Execute Rollback

```bash
# Get connection string
CONNECTION_STRING=$(az keyvault secret show \
    --vault-name kv-stitches-staging \
    --name DatabaseConnectionString \
    --query value -o tsv)

# Execute rollback
cd backend
ConnectionStrings__DefaultConnection="$CONNECTION_STRING" \
    dotnet ef database update <target-migration> \
    --project src/Infrastructure \
    --startup-project src/Api
```

### Step 4: Verify Rollback

```bash
# Check current migration state
ConnectionStrings__DefaultConnection="$CONNECTION_STRING" \
    dotnet ef migrations list --project src/Infrastructure --startup-project src/Api
```

### Step 5: Restart Application

```bash
az webapp start --resource-group stitches-staging --name app-stitches-staging
```

### Step 6: Run Smoke Tests

```bash
./infrastructure/scripts/smoke-test.sh staging
```

## Removing a Bad Migration

If a migration was applied locally but should be removed:

```bash
# 1. Roll back the database
dotnet ef database update <previous-migration> \
    --project src/Infrastructure --startup-project src/Api

# 2. Remove the migration file
dotnet ef migrations remove \
    --project src/Infrastructure --startup-project src/Api
```

## Data-Destructive Migrations

Some rollbacks may cause data loss. Check the migration SQL:

```bash
# Generate rollback SQL for review
dotnet ef migrations script <target-migration> <current-migration> \
    --project src/Infrastructure --startup-project src/Api \
    > rollback.sql

# Review rollback.sql for DROP commands
cat rollback.sql | grep -i "DROP"
```

**Warning**: If DROP commands affect tables with data, consider:
1. Backing up the data first
2. Planning data migration scripts
3. Notifying stakeholders

## Emergency: Reset to Initial State

**Extreme caution - destroys all data**

```bash
# Drop and recreate database
az sql db delete --resource-group stitches-staging --server sql-stitches-staging --name db-stitches-staging --yes

az sql db create --resource-group stitches-staging --server sql-stitches-staging --name db-stitches-staging --service-objective S0

# Rerun all migrations
dotnet ef database update --project src/Infrastructure --startup-project src/Api
```

## Prevention

1. **Test migrations locally** before pushing to main
2. **Review migration SQL** before deploying to production
3. **Use staging environment** to validate migrations
4. **Create backups** before major migrations
5. **Schedule maintenance windows** for data-destructive migrations

## Escalation

If unable to resolve:

1. Contact DBA if available
2. Review Azure SQL server logs
3. Open Azure support ticket

---

**Last Updated**: 2026-01-31
