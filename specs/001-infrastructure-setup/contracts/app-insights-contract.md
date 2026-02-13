# Application Insights Telemetry Contract

**Feature**: 001-infrastructure-setup  
**Date**: 2026-01-31  
**Purpose**: Define expected telemetry schema for monitoring and alerting

---

## Overview

Application Insights captures telemetry from the Stitches API automatically via SDK instrumentation. This document defines the schema for standard and custom telemetry to ensure consistent monitoring across environments.

**Instrumentation**: `Microsoft.ApplicationInsights.AspNetCore` SDK with auto-instrumentation enabled

**Correlation**: Distributed tracing enabled with `Operation-Id` header propagation from frontend to backend

---

## Standard Telemetry Types

### 1. Request Telemetry

**Purpose**: Captures all HTTP requests to the API

**Automatically Captured Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | HTTP method + route pattern | `GET /api/health` |
| `url` | string | Full request URL | `https://stitches-staging.azurewebsites.net/api/health` |
| `duration` | number | Request processing time (ms) | `42` |
| `responseCode` | number | HTTP status code | `200` |
| `success` | boolean | Whether request succeeded (2xx/3xx = true) | `true` |
| `timestamp` | datetime | Request timestamp (ISO 8601) | `2026-01-31T20:30:00.000Z` |
| `operationId` | string | Correlation ID for distributed tracing | `abc123...` |
| `userId` | string | Authenticated user ID (if JWT present) | `user-456` |
| `sessionId` | string | Browser session ID (from frontend) | `session-789` |
| `properties.environment` | string | Environment name | `staging` |

**Performance Alert Threshold** (per Constitution):
- ⚠️ Alert if `duration` (p95) > 500ms
- ⚠️ Alert if `duration` (p95) > 200ms excluding `/api/images/process` (async endpoint)

---

### 2. Dependency Telemetry

**Purpose**: Captures outbound calls to dependencies (database, blob storage, external APIs)

**Automatically Captured Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `name` | string | Dependency name | `SQL: stitches-db` |
| `type` | string | Dependency type | `SQL`, `HTTP`, `Azure blob` |
| `target` | string | Dependency endpoint | `stitches-db.database.windows.net` |
| `data` | string | Query or request (sanitized, no secrets) | `SELECT ... FROM Designs WHERE userId = @p0` |
| `duration` | number | Dependency call time (ms) | `15` |
| `success` | boolean | Whether call succeeded | `true` |
| `resultCode` | string | SQL error code or HTTP status | `0` (success), `53` (connection timeout) |
| `timestamp` | datetime | Call timestamp | `2026-01-31T20:30:00.100Z` |
| `operationId` | string | Parent request correlation ID | `abc123...` |

**Performance Monitoring**:
- Database queries should be < 100ms (p95)
- Blob storage reads should be < 200ms (p95)
- Key Vault secret retrieval should be < 50ms (p95)

---

### 3. Exception Telemetry

**Purpose**: Captures unhandled exceptions and errors

**Automatically Captured Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `type` | string | Exception type (full name) | `System.Data.SqlClient.SqlException` |
| `message` | string | Exception message | `Connection timeout expired` |
| `stackTrace` | string | Full stack trace | `at Stitches.Infrastructure.Data...` |
| `severityLevel` | string | Error severity | `Error`, `Critical` |
| `timestamp` | datetime | Exception timestamp | `2026-01-31T20:30:00.000Z` |
| `operationId` | string | Request correlation ID | `abc123...` |
| `properties.method` | string | Controller/method name | `HealthController.Get` |
| `properties.userId` | string | User ID if authenticated | `user-456` |

**Error Rate Alert Threshold** (per Constitution):
- ⚠️ Alert if error rate > 1% of total requests

---

### 4. Trace Telemetry

**Purpose**: Captures application log messages (structured logging via `ILogger`)

**Automatically Captured Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `message` | string | Log message | `Database migration applied: 20260131_InitialCreate` |
| `severityLevel` | string | Log level | `Information`, `Warning`, `Error` |
| `timestamp` | datetime | Log timestamp | `2026-01-31T20:30:00.000Z` |
| `operationId` | string | Request correlation ID | `abc123...` |
| `properties.*` | various | Structured properties | `properties.migrationName: "20260131_InitialCreate"` |

**Best Practices**:
- Use structured logging: `_logger.LogInformation("Migration applied: {MigrationName}", name)`
- Avoid logging secrets: Never log connection strings, passwords, tokens
- Log levels:
  - `Trace`: Detailed diagnostic info (disabled in production)
  - `Debug`: Debugging info (disabled in production)
  - `Information`: General informational messages
  - `Warning`: Potential issues (e.g., retry after transient failure)
  - `Error`: Errors that stop current operation
  - `Critical`: Fatal errors requiring immediate attention

---

## Custom Telemetry Events

### Event: `Deployment Started`

**Purpose**: Tracks deployment initiation for monitoring pipeline progress

**Custom Properties**:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `environment` | string | Target environment | `staging` |
| `gitCommitSha` | string | Source commit hash | `8f2eb868...` |
| `gitBranch` | string | Source branch | `main` |
| `triggeredBy` | string | User or system | `github-actions` |
| `deploymentId` | string | Unique deployment ID | `a1b2c3d4-...` |

**Example Code**:
```csharp
_telemetryClient.TrackEvent("Deployment Started", new Dictionary<string, string>
{
    { "environment", "staging" },
    { "gitCommitSha", "8f2eb868..." },
    { "gitBranch", "main" },
    { "triggeredBy", "github-actions" },
    { "deploymentId", Guid.NewGuid().ToString() }
});
```

---

### Event: `Migration Executed`

**Purpose**: Tracks database migration execution for auditing and troubleshooting

**Custom Properties**:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `migrationName` | string | EF Core migration name | `20260131_InitialCreate` |
| `status` | string | Execution result | `success`, `failed`, `rolled-back` |
| `durationMs` | number | Migration execution time | `1500` |
| `environment` | string | Target environment | `staging` |
| `error` | string | Error message if failed | `Column 'userId' already exists` |

**Example Code**:
```csharp
_telemetryClient.TrackEvent("Migration Executed", new Dictionary<string, string>
{
    { "migrationName", "20260131_InitialCreate" },
    { "status", "success" },
    { "durationMs", "1500" },
    { "environment", "staging" }
});
```

---

### Event: `Health Check Failed`

**Purpose**: Tracks health check failures for alerting and diagnostics

**Custom Properties**:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `endpoint` | string | Health check endpoint | `/api/health` |
| `responseCode` | number | HTTP status code | `503` |
| `responseTimeMs` | number | Response time (if available) | `5000` |
| `error` | string | Error description | `Database connection timeout` |
| `environment` | string | Target environment | `staging` |

**Example Code**:
```csharp
_telemetryClient.TrackEvent("Health Check Failed", new Dictionary<string, string>
{
    { "endpoint", "/api/health" },
    { "responseCode", "503" },
    { "responseTimeMs", "5000" },
    { "error", "Database connection timeout" },
    { "environment", "staging" }
});
```

---

## Metrics (Performance Counters)

### Custom Metric: `DeploymentDuration`

**Purpose**: Track end-to-end deployment time for SLO monitoring

**Captured Values**:
- **Value**: Duration in seconds
- **Dimensions**: `environment` (dev/staging/prod), `status` (success/failed)

**Example Code**:
```csharp
_telemetryClient.TrackMetric("DeploymentDuration", durationSeconds, new Dictionary<string, string>
{
    { "environment", "staging" },
    { "status", "success" }
});
```

**Target SLO** (per Success Criteria):
- ✅ Staging deployment should complete in < 600 seconds (10 minutes)

---

### Custom Metric: `SmokeTestDuration`

**Purpose**: Track smoke test execution time

**Captured Values**:
- **Value**: Duration in milliseconds
- **Dimensions**: `environment`, `status` (passed/failed/timeout)

**Example Code**:
```csharp
_telemetryClient.TrackMetric("SmokeTestDuration", durationMs, new Dictionary<string, string>
{
    { "environment", "staging" },
    { "status", "passed" }
});
```

**Target SLO** (per Success Criteria):
- ✅ Smoke tests should complete in < 30,000 ms (30 seconds)

---

## Availability Monitoring

### Availability Test: `Health Check Ping`

**Purpose**: External monitoring of API availability from multiple global locations

**Configuration**:
- **URL**: `https://stitches-[environment].azurewebsites.net/api/health`
- **Frequency**: Every 5 minutes
- **Locations**: At least 3 Azure regions (e.g., East US, West Europe, Southeast Asia)
- **Expected Response**: 200 OK with `status: "healthy"` in body
- **Timeout**: 10 seconds
- **Alert Threshold**: Alert if availability drops below 99.5% over 30-day window (per Constitution)

**Setup**:
```bash
# Create availability test via Azure CLI
az monitor app-insights web-test create \
  --resource-group stitches-staging \
  --name "health-check-ping" \
  --location "eastus" \
  --kind "ping" \
  --web-test "https://stitches-staging.azurewebsites.net/api/health" \
  --frequency 300 \
  --timeout 10
```

---

## Alert Rules (Constitution Requirements)

### Alert: `High API Latency`

**Condition**: Request duration (p95) > 500ms for 5 consecutive minutes

**Action**: Send email/Slack notification to team

**Query**:
```kusto
requests
| where timestamp > ago(5m)
| summarize p95=percentile(duration, 95) by bin(timestamp, 1m)
| where p95 > 500
```

---

### Alert: `Low Availability`

**Condition**: Availability < 99.5% over 30-day rolling window

**Action**: Send email/Slack notification to team

**Query**:
```kusto
availabilityResults
| where timestamp > ago(30d)
| summarize availability=100.0 * countif(success == true) / count()
| where availability < 99.5
```

---

### Alert: `High Error Rate`

**Condition**: Error rate > 1% over 5-minute window

**Action**: Send email/Slack notification to team

**Query**:
```kusto
requests
| where timestamp > ago(5m)
| summarize errorRate=100.0 * countif(success == false) / count()
| where errorRate > 1.0
```

---

## Security & Privacy

### Do Not Log

- **Secrets**: Connection strings, passwords, API keys, tokens, certificates
- **PII**: Email addresses, IP addresses (unless required for security audit)
- **Request bodies**: May contain sensitive user data (except sanitized examples for debugging)

### Sanitization Patterns

**SQL Queries**: Parameterized queries are automatically sanitized by EF Core ("@p0", "@p1")

**HTTP Headers**: Authorization header is automatically redacted by Application Insights

**Exception Messages**: Ensure exception messages don't leak connection strings or secrets

---

## Validation Against Success Criteria

- ✅ **SC-007**: Smoke test duration (custom metric) verifies < 30s completion
- ✅ **SC-008**: Request, Dependency, Exception telemetry ensure comprehensive monitoring
- ✅ **SC-009**: Security guidelines enforce no secrets in logs
- ✅ **SC-006**: Deployment duration (custom metric) tracks < 10 min target

---

**Status**: Telemetry contract complete. Ready for implementation.
