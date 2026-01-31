# Data Model Design: Infrastructure Setup

**Feature**: 001-infrastructure-setup  
**Date**: 2026-01-31  
**Purpose**: Define entities and relationships for infrastructure, deployment, and configuration management

**Note**: This is a conceptual data model for infrastructure metadata. Actual implementation may be configuration files (JSON, YAML) or Azure Resource Manager state rather than database tables.

---

## Entity: Environment Configuration

**Purpose**: Represents environment-specific settings for dev, staging, and production deployments.

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `name` | string | Environment identifier | Required. One of: "dev", "staging", "prod" |
| `resourceTier` | string | Azure resource SKU tier | Required. E.g., "B1" (Basic), "S1" (Standard), "P1v2" (Premium) |
| `instanceCount` | integer | Number of App Service instances | Required. ≥1 for dev/staging, ≥2 for prod |
| `backupStrategy` | string | Database backup configuration | Required. "simple" for dev, "zone-redundant" for prod |
| `storageReplication` | string | Blob storage replication mode | Required. "LRS" for dev/staging, "RA-GRS" for prod |
| `monitoringThresholds` | object | Performance alert thresholds | Required. Contains `latencyP95Ms`, `errorRatePercent`, `availabilityPercent` |
| `region` | string | Azure region | Required. E.g., "eastus" |
| `costBudgetUSD` | number | Monthly cost alert threshold | Optional. Default: 500 for all environments |

### Validation Rules

- `instanceCount` must be ≥2 when `name` is "prod"
- `backupStrategy` must be "zone-redundant" when `name` is "prod"
- `storageReplication` must be "RA-GRS" when `name` is "prod"
- `region` must be a valid Azure region identifier

### Relationships

- **Has Many** `InfrastructureResource`: Each environment has multiple Azure resources

### Example

```json
{
  "name": "prod",
  "resourceTier": "P1v2",
  "instanceCount": 2,
  "backupStrategy": "zone-redundant",
  "storageReplication": "RA-GRS",
  "monitoringThresholds": {
    "latencyP95Ms": 500,
    "errorRatePercent": 1.0,
    "availabilityPercent": 99.5
  },
  "region": "eastus",
  "costBudgetUSD": 500
}
```

---

## Entity: Infrastructure Resource

**Purpose**: Represents a single Azure resource provisioned via Infrastructure as Code.

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `id` | string | Unique resource identifier | Required. Azure resource ID format |
| `type` | string | Azure resource type | Required. One of: "AppService", "SqlDatabase", "BlobStorage", "KeyVault", "ApplicationInsights", "CDN", "AppServicePlan" |
| `name` | string | Resource name | Required. Must follow Azure naming conventions |
| `region` | string | Azure region | Required. E.g., "eastus" |
| `environmentName` | string | Parent environment | Required. Foreign key to Environment Configuration |
| `configuration` | object | Resource-specific parameters | Required. JSON object with type-specific settings |
| `status` | string | Provisioning status | Required. One of: "provisioning", "ready", "failed", "deleting" |
| `createdAt` | datetime | Resource creation timestamp | Required. ISO 8601 format |
| `updatedAt` | datetime | Last update timestamp | Required. ISO 8601 format |

### Relationships

- **Belongs To** `EnvironmentConfiguration`: Each resource belongs to one environment
- **References** Other `InfrastructureResource`: E.g., App Service references App Service Plan, Key Vault

### Example

```json
{
  "id": "/subscriptions/{sub-id}/resourceGroups/stitches-prod/providers/Microsoft.Web/sites/stitches-prod",
  "type": "AppService",
  "name": "stitches-prod",
  "region": "eastus",
  "environmentName": "prod",
  "configuration": {
    "appServicePlanId": "/subscriptions/{sub-id}/resourceGroups/stitches-prod/providers/Microsoft.Web/serverfarms/plan-stitches-prod",
    "httpsOnly": true,
    "managedIdentity": "SystemAssigned",
    "keyVaultReference": "/subscriptions/{sub-id}/resourceGroups/stitches-prod/providers/Microsoft.KeyVault/vaults/kv-stitches-prod"
  },
  "status": "ready",
  "createdAt": "2026-01-31T20:00:00Z",
  "updatedAt": "2026-01-31T20:15:00Z"
}
```

---

## Entity: Deployment

**Purpose**: Represents a single deployment operation to an environment, tracking artifacts, migrations, and health status.

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `id` | string | Unique deployment identifier | Required. UUID format |
| `environmentName` | string | Target environment | Required. One of: "dev", "staging", "prod" |
| `timestamp` | datetime | Deployment start time | Required. ISO 8601 format |
| `triggeredBy` | string | User or system that initiated | Required. E.g., "github-actions", "user@example.com" |
| `gitCommitSha` | string | Source code commit hash | Required. Git SHA-1 format (40 hex chars) |
| `gitBranch` | string | Source branch | Required. E.g., "main", "feature/001" |
| `frontendArtifact` | object | React bundle metadata | Required. Contains `path`, `sizeBytes`, `buildDurationMs` |
| `backendArtifact` | object | .NET publish metadata | Required. Contains `path`, `sizeBytes`, `buildDurationMs` |
| `migrationStatus` | string | Database migration result | Required. One of: "not-required", "success", "failed", "rolled-back" |
| `migrationsApplied` | array | List of migrations executed | Optional. Array of migration names |
| `healthCheckStatus` | string | Post-deployment health check | Required. One of: "passed", "failed", "timeout" |
| `healthCheckResponseTimeMs` | number | Health endpoint latency | Optional. Null if health check failed |
| `deploymentStatus` | string | Overall deployment result | Required. One of: "in-progress", "success", "failed" |
| `completedAt` | datetime | Deployment end time | Optional. Null if still in progress |
| `durationSeconds` | number | Total deployment time | Optional. Calculated from timestamp to completedAt |

### State Transitions

```
in-progress → success (if tests pass, migrations succeed, health check passes)
in-progress → failed (if any step fails)
```

### Relationships

- **Belongs To** `EnvironmentConfiguration`: Each deployment targets one environment

### Example

```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "environmentName": "staging",
  "timestamp": "2026-01-31T20:30:00Z",
  "triggeredBy": "github-actions",
  "gitCommitSha": "8f2eb8688d01e28f36008db8a60271064607db87",
  "gitBranch": "main",
  "frontendArtifact": {
    "path": "frontend/dist",
    "sizeBytes": 1048576,
    "buildDurationMs": 45000
  },
  "backendArtifact": {
    "path": "backend/publish",
    "sizeBytes": 52428800,
    "buildDurationMs": 120000
  },
  "migrationStatus": "success",
  "migrationsApplied": ["20260131_InitialCreate"],
  "healthCheckStatus": "passed",
  "healthCheckResponseTimeMs": 42,
  "deploymentStatus": "success",
  "completedAt": "2026-01-31T20:40:00Z",
  "durationSeconds": 600
}
```

---

## Entity: Secret

**Purpose**: Represents sensitive configuration stored in Azure Key Vault, with audit trail. **NEVER stores actual secret values in this model.**

### Properties

| Property | Type | Description | Constraints |
|----------|------|-------------|-------------|
| `name` | string | Secret identifier | Required. E.g., "DatabaseConnectionString", "OAuthClientSecret" |
| `keyVaultUrl` | string | Azure Key Vault URL | Required. E.g., "https://kv-stitches-prod.vault.azure.net/" |
| `type` | string | Secret category | Required. One of: "ConnectionString", "ApiKey", "Certificate", "Other" |
| `rotationScheduleDays` | number | Days between required rotations | Optional. Default: 90 |
| `lastRotatedAt` | datetime | Last rotation timestamp | Optional. Null if never rotated |
| `nextRotationDue` | datetime | Next required rotation | Optional. Calculated from lastRotatedAt + rotationScheduleDays |
| `lastAccessedAt` | datetime | Last retrieval timestamp | Optional. Updated by Key Vault audit logs |
| `createdBy` | string | User or system that created secret | Required. E.g., "admin@example.com", "terraform" |
| `environmentName` | string | Associated environment | Required. One of: "dev", "staging", "prod" |
| `isActive` | boolean | Whether secret is currently used | Required. Default: true |

### Security Constraints

- **NEVER** store the actual secret value in this model
- **NEVER** log secret values in application logs
- **ALWAYS** retrieve secrets at runtime from Key Vault via Managed Identity
- **ALWAYS** use `::add-mask::` in CI/CD logs for dynamic secrets

### Relationships

- **Belongs To** `EnvironmentConfiguration`: Each secret is environment-specific

### Example

```json
{
  "name": "DatabaseConnectionString",
  "keyVaultUrl": "https://kv-stitches-prod.vault.azure.net/",
  "type": "ConnectionString",
  "rotationScheduleDays": 90,
  "lastRotatedAt": "2026-01-15T10:00:00Z",
  "nextRotationDue": "2026-04-15T10:00:00Z",
  "lastAccessedAt": "2026-01-31T20:35:00Z",
  "createdBy": "terraform",
  "environmentName": "prod",
  "isActive": true
}
```

---

## Entity Relationships Diagram

```
EnvironmentConfiguration (1) ──< (Many) InfrastructureResource
EnvironmentConfiguration (1) ──< (Many) Deployment
EnvironmentConfiguration (1) ──< (Many) Secret

InfrastructureResource (Many) ──< (Many) InfrastructureResource [self-reference for dependencies]
```

---

## Implementation Notes

### Storage Strategy

- **Environment Configuration**: Stored in Bicep parameter files (`dev.parameters.json`, `staging.parameters.json`, `prod.parameters.json`)
- **Infrastructure Resource**: Managed by Azure Resource Manager state (queryable via Azure CLI/SDK)
- **Deployment**: Could be stored in:
  - GitHub Actions run history (short-term, 90 days retention)
  - Application Insights custom events (long-term, queryable)
  - Azure SQL Database table (if deployment history becomes feature requirement in v1.1)
- **Secret**: Metadata stored in Key Vault tags (not as separate database), actual values in Key Vault secrets

### Query Patterns

**Get all resources for an environment**:
```bash
az resource list --resource-group stitches-staging --output json
```

**Get latest deployment for environment**:
```bash
az deployment group list --resource-group stitches-staging --query "[0]"
```

**Check secret rotation status**:
```bash
az keyvault secret show --vault-name kv-stitches-prod --name DatabaseConnectionString --query attributes
```

---

## Validation Against Success Criteria

- ✅ **SC-005**: Environment Configuration ensures correct resource tiers per environment
- ✅ **SC-006**: Deployment entity tracks CI/CD completion time (durationSeconds ≤ 600)
- ✅ **SC-007**: Deployment entity tracks health check status and response time
- ✅ **SC-009**: Secret entity enforces "never store values" principle

---

**Status**: Data model complete. Ready for API contract design.
