# Key Vault Access Issues Runbook

This runbook provides troubleshooting steps for Azure Key Vault access problems with Managed Identity.

## Symptoms

- Application fails to start with Key Vault errors
- 403 Forbidden when accessing secrets
- "Access denied" or "Unauthorized" in application logs
- Secrets not being injected into configuration

## Quick Diagnosis

### 1. Check App Service Managed Identity

```bash
# Verify Managed Identity is enabled
az webapp show \
    --resource-group stitches-staging \
    --name app-stitches-staging \
    --query "identity" \
    --output json
```

Expected output should include:
```json
{
  "principalId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "type": "SystemAssigned"
}
```

### 2. Check Key Vault Access Policies

```bash
# List Key Vault access policies (if using access policies)
az keyvault show \
    --name kv-stitches-staging \
    --query "properties.accessPolicies" \
    --output table
```

### 3. Check RBAC Role Assignments

```bash
# Get App Service principal ID
PRINCIPAL_ID=$(az webapp show \
    --resource-group stitches-staging \
    --name app-stitches-staging \
    --query "identity.principalId" \
    --output tsv)

# List role assignments for the principal
az role assignment list \
    --assignee $PRINCIPAL_ID \
    --output table
```

## Resolution Steps

### Step 1: Enable Managed Identity (if not enabled)

```bash
az webapp identity assign \
    --resource-group stitches-staging \
    --name app-stitches-staging
```

### Step 2: Grant Key Vault Secrets User Role (RBAC)

```bash
# Get Key Vault resource ID
KEY_VAULT_ID=$(az keyvault show \
    --name kv-stitches-staging \
    --query "id" \
    --output tsv)

# Get App Service principal ID
PRINCIPAL_ID=$(az webapp show \
    --resource-group stitches-staging \
    --name app-stitches-staging \
    --query "identity.principalId" \
    --output tsv)

# Assign Key Vault Secrets User role
az role assignment create \
    --role "Key Vault Secrets User" \
    --assignee $PRINCIPAL_ID \
    --scope $KEY_VAULT_ID
```

### Step 3: Verify Secret Exists

```bash
# List secrets in Key Vault
az keyvault secret list \
    --vault-name kv-stitches-staging \
    --output table

# Check specific secret
az keyvault secret show \
    --vault-name kv-stitches-staging \
    --name DatabaseConnectionString \
    --query "id"
```

### Step 4: Restart App Service

After granting access, restart the App Service to refresh the identity token:

```bash
az webapp restart \
    --resource-group stitches-staging \
    --name app-stitches-staging
```

### Step 5: Check Application Logs

```bash
az webapp log tail \
    --resource-group stitches-staging \
    --name app-stitches-staging
```

## Common Issues

### Issue: "The user, group or application does not have secrets get permission"

**Cause**: Missing RBAC role or access policy

**Resolution**:
```bash
# Grant Key Vault Secrets User role
az role assignment create \
    --role "Key Vault Secrets User" \
    --assignee $PRINCIPAL_ID \
    --scope $KEY_VAULT_ID
```

### Issue: "Key Vault is not accessible"

**Cause**: Network restrictions or firewall rules

**Check**:
```bash
az keyvault show \
    --name kv-stitches-staging \
    --query "properties.networkAcls"
```

**Resolution**:
```bash
# Allow Azure services
az keyvault update \
    --name kv-stitches-staging \
    --bypass AzureServices \
    --default-action Allow
```

### Issue: "Managed Identity not found"

**Cause**: Identity was disabled or not propagated

**Resolution**:
```bash
# Disable and re-enable
az webapp identity assign \
    --resource-group stitches-staging \
    --name app-stitches-staging
```

### Issue: "Token expired or invalid"

**Cause**: Cached identity token is stale

**Resolution**: Restart the App Service
```bash
az webapp restart \
    --resource-group stitches-staging \
    --name app-stitches-staging
```

## Local Development

For local development, use Azure CLI authentication:

```csharp
// Program.cs
var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    ExcludeManagedIdentityCredential = true // Use CLI/VS credentials locally
});
```

Ensure you're logged in:
```bash
az login
```

## RBAC vs Access Policies

Our infrastructure uses RBAC (Role-Based Access Control). If switching between models:

```bash
# Check authorization mode
az keyvault show \
    --name kv-stitches-staging \
    --query "properties.enableRbacAuthorization"

# Enable RBAC (recommended)
az keyvault update \
    --name kv-stitches-staging \
    --enable-rbac-authorization true
```

## Audit Logs

Check Key Vault audit logs for access attempts:

```bash
# Query diagnostic logs (requires Azure Monitor)
az monitor log-analytics query \
    --workspace <workspace-id> \
    --analytics-query "AzureDiagnostics | where ResourceProvider == 'MICROSOFT.KEYVAULT' | where ResultSignature == 'Forbidden' | take 10"
```

## Escalation

If unable to resolve:

1. Verify Azure AD permissions
2. Check for Azure service outages
3. Open Azure support ticket (include Key Vault name, App Service name, and principal ID)

---

**Last Updated**: 2026-01-31
