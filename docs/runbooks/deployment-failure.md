# Deployment Failure Runbook

This runbook provides troubleshooting steps for failed deployments in the Stitches application.

## Quick Diagnosis

### 1. Check GitHub Actions Logs

1. Go to [GitHub Actions](https://github.com/aaronolds/stitches/actions)
2. Find the failed workflow run
3. Click on the failed job to see detailed logs
4. Look for error messages in red

### 2. Common Failure Points

| Stage | Common Causes |
|-------|---------------|
| `test-*` | Test failures, missing dependencies |
| `build-*` | TypeScript errors, compilation failures |
| `provision-infrastructure` | Azure permission issues, Bicep syntax errors |
| `migrate-database` | Connection string issues, migration conflicts |
| `deploy-app` | App Service issues, file permissions |
| `smoke-test` | Application not starting, health check failing |

## Troubleshooting by Stage

### Test Failures

```bash
# Reproduce locally
cd frontend && npm ci && npm test
cd backend && dotnet test
```

**Resolution**: Fix failing tests before redeploying.

### Build Failures

```bash
# Check frontend build
cd frontend && npm run build

# Check backend build
cd backend && dotnet build --warnaserror
```

**Resolution**: Fix TypeScript/C# compilation errors.

### Infrastructure Provisioning Failures

**Symptoms**: `provision-infrastructure` job fails

**Common Causes**:

1. **Insufficient permissions**: Service principal lacks required Azure roles
2. **Bicep syntax errors**: Invalid template
3. **Resource conflicts**: Resource already exists with same name
4. **Quota exceeded**: Subscription limits reached

**Diagnosis**:

```bash
# Validate Bicep locally
az bicep build --file infrastructure/bicep/main.bicep

# Check Azure deployment history
az deployment group list --resource-group stitches-staging --output table

# Get detailed deployment error
az deployment group show --resource-group stitches-staging --name <deployment-name> --query "properties.error"
```

**Resolution**:

- Fix Bicep syntax errors
- Request quota increase
- Delete conflicting resources
- Update service principal permissions

### Database Migration Failures

**Symptoms**: `migrate-database` job fails

**Common Causes**:

1. **Connection string invalid**: Wrong Key Vault secret value
2. **Migration conflicts**: Pending migrations or model drift
3. **Database locked**: Concurrent access issues

**Diagnosis**:

```bash
# Check pending migrations
cd backend
dotnet ef migrations list --project src/Infrastructure --startup-project src/Api

# Get migration SQL script for review
dotnet ef migrations script --project src/Infrastructure --startup-project src/Api
```

**Resolution**:

- Verify connection string in Key Vault
- Review pending migrations
- See [Migration Rollback Runbook](migration-rollback.md)

### Application Deployment Failures

**Symptoms**: `deploy-app` job fails

**Common Causes**:

1. **Package issues**: Corrupted artifacts
2. **Startup failures**: Missing configuration
3. **Permission issues**: Managed Identity not configured

**Diagnosis**:

```bash
# Check App Service logs
az webapp log tail --resource-group stitches-staging --name app-stitches-staging

# Check App Service status
az webapp show --resource-group stitches-staging --name app-stitches-staging --query "state"
```

**Resolution**:

- Re-run deployment
- Check App Service configuration
- Verify Key Vault access

### Smoke Test Failures

**Symptoms**: `smoke-test` job fails

**Common Causes**:

1. **Application not started**: Startup exception
2. **Health endpoint not responding**: Routing issues
3. **Timeout**: Slow cold start

**Diagnosis**:

```bash
# Manual health check
curl -v https://app-stitches-staging.azurewebsites.net/api/health

# Check application logs
az webapp log tail --resource-group stitches-staging --name app-stitches-staging
```

**Resolution**:

- Review application startup logs
- Check health endpoint implementation
- Verify all dependencies (database, Key Vault) are accessible

## Emergency Rollback

If deployment causes production issues:

### Option 1: Redeploy Previous Version

1. Go to GitHub Actions
2. Find last successful deployment
3. Click "Re-run all jobs"

### Option 2: Swap Deployment Slots (if configured)

```bash
az webapp deployment slot swap \
    --resource-group stitches-prod \
    --name app-stitches-prod \
    --slot staging \
    --target-slot production
```

### Option 3: Disable App Service (Circuit Breaker)

```bash
az webapp stop --resource-group stitches-prod --name app-stitches-prod
```

## Cost Management Alerts

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

## Escalation

If unable to resolve:

1. Check Azure Service Health for outages
2. Review recent code changes in Git
3. Contact team lead
4. Open Azure support ticket (Sev B for staging, Sev A for prod)

---

**Last Updated**: 2026-01-31
