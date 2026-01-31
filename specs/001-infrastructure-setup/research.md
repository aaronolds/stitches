# Research Findings: Infrastructure Setup

**Feature**: 001-infrastructure-setup  
**Date**: 2026-01-31  
**Purpose**: Resolve technology choices and document best practices for implementation

---

## Frontend Development

### Decision: Vite Configuration for React + TypeScript

**Rationale**:
- Vite 5+ provides native ESM support with instant HMR (<1s update time)
- TypeScript strict mode enabled for type safety and maintainability
- Plugin ecosystem: @vitejs/plugin-react enables Fast Refresh
- Environment variable pattern: `VITE_` prefix exposes vars to client-side code
- Build output: optimized chunks with tree-shaking and code splitting

**Configuration Pattern**:
```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:5000'  // Backend proxy for CORS
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})
```

**Alternatives Considered**:
- Create React App: Slower build times, more complex configuration
- Webpack: More configuration overhead, slower HMR
- **Rejected because**: Vite's speed advantage is critical for developer experience (<1s HMR target)

---

### Decision: Vitest Setup for Component Testing

**Rationale**:
- Native Vite integration, no additional configuration overhead
- Jest-compatible API for easy migration and familiar syntax
- JSDOM environment for React component rendering
- React Testing Library integration for user-centric testing
- Watch mode with HMR for instant test feedback

**Configuration Pattern**:
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './tests/setup.ts'
  }
})
```

**Alternatives Considered**:
- Jest: Requires additional Babel configuration, slower test runs
- Cypress Component Testing: Heavier solution, better for E2E
- **Rejected because**: Vitest's speed and Vite integration align with HMR performance goals

---

### Decision: ESLint + Prettier Integration

**Rationale**:
- ESLint enforces React best practices (hooks rules, accessibility)
- Prettier handles formatting automatically, reducing bikeshedding
- Pre-commit hooks via Husky ensure code quality before commit
- VSCode integration provides real-time feedback

**Configuration Pattern**:
```json
// .eslintrc.js
module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier'  // Must be last to disable conflicting rules
  ],
  rules: {
    'react/react-in-jsx-scope': 'off'  // Not needed in React 18+
  }
}
```

**Alternatives Considered**:
- No linter: Inconsistent code style, no enforceable standards
- StandardJS: Less flexible, no TypeScript support
- **Rejected because**: ESLint + Prettier is industry standard with strong TypeScript support

---

### Decision: Environment Variable Management in Vite

**Rationale**:
- `.env.local` for local overrides (gitignored, developer-specific)
- `.env.example` documents required variables for new developers
- `VITE_` prefix: Only these vars are bundled into client-side code
- `import.meta.env.VITE_API_URL`: Type-safe access in TypeScript

**Pattern**:
```bash
# .env.local (gitignored)
VITE_API_URL=http://localhost:5000

# .env.example (committed)
VITE_API_URL=http://localhost:5000
```

**Alternatives Considered**:
- Hardcoded URLs: No flexibility across environments
- Runtime config: Requires additional API call, slower initial load
- **Rejected because**: Build-time injection is faster and simpler for MVP

---

## Backend Development

### Decision: ASP.NET Core 10+ Layered Architecture

**Rationale**:
- Follows SDD Section 8.1 requirements (API, Application, Domain, Infrastructure)
- Clean Architecture principles: dependencies point inward (Domain has no dependencies)
- Testability: Each layer can be tested independently with mocked dependencies
- Scalability: Business logic (Application) separated from HTTP concerns (API)

**Structure Pattern**:
```
backend/src/
├── Api/                    # Controllers, Middleware, Program.cs
├── Application/            # Use cases, DTOs, Interfaces
├── Domain/                 # Entities, Value Objects, Domain Services
└── Infrastructure/         # EF Core, Azure clients, External APIs
```

**Alternatives Considered**:
- Single project: Faster initial setup but harder to maintain as complexity grows
- Vertical Slice Architecture: Good for feature isolation but requires more upfront planning
- **Rejected because**: Layered architecture is Constitution-mandated and team-familiar

---

### Decision: xUnit + NSubstitute for Testing

**Rationale**:
- xUnit: .NET Foundation standard, parallel test execution by default
- NSubstitute: Per Constitution v1.1.1, cleaner API than Moq
- Flexible mocking syntax: `substitute.Method().Returns(value)`
- Supports async/await patterns natively
- AAA pattern (Arrange, Act, Assert) aligns with team conventions

**Test Pattern**:
```csharp
[Fact]
public async Task HealthCheck_ReturnsOk()
{
    // Arrange
    var controller = new HealthController();
    
    // Act
    var result = await controller.Get();
    
    // Assert
    var okResult = Assert.IsType<OkObjectResult>(result);
    Assert.Equal(200, okResult.StatusCode);
}
```

**Alternatives Considered**:
- Moq: Previously used, but NSubstitute has simpler API for complex scenarios
- FakeItEasy: Similar to NSubstitute but less community adoption
- **Rejected because**: Constitution v1.1.1 mandates NSubstitute for consistency

---

### Decision: Swagger/OpenAPI Integration

**Rationale**:
- Swashbuckle.AspNetCore generates OpenAPI spec from C# models
- `/swagger` endpoint provides interactive API documentation
- Development-only: Disabled in production via environment check
- Supports JWT bearer authentication documentation (for Feature 1)

**Configuration Pattern**:
```csharp
// Program.cs
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Stitches API",
        Version = "v1"
    });
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
```

**Alternatives Considered**:
- Manual OpenAPI YAML: More control but requires manual maintenance
- NSwag: Similar to Swashbuckle but less mature ecosystem
- **Rejected because**: Swashbuckle is industry standard with minimal configuration

---

### Decision: EF Core Migration Workflow

**Rationale**:
- Code-First migrations: Database schema generated from C# entity classes
- Version control: Migration files committed to Git for team sync
- LocalDB for local dev: No external database setup required
- Azure SQL Database for cloud: Connection string from Key Vault

**Migration Commands**:
```bash
# Create migration
dotnet ef migrations add InitialCreate --project src/Infrastructure

# Apply to local database
dotnet ef database update --project src/Infrastructure

# Generate SQL script for review
dotnet ef migrations script --project src/Infrastructure
```

**Alternatives Considered**:
- Database-First: Requires SQL skills, harder to version control
- Dapper (no ORM): More control but more boilerplate for CRUD
- **Rejected because**: EF Core aligns with layered architecture and provides change tracking

---

### Decision: User Secrets for Local Development

**Rationale**:
- `dotnet user-secrets` stores secrets outside project directory
- Per-user configuration: No risk of committing secrets to Git
- JSON format: Same structure as appsettings.json
- Automatic loading in Development environment

**Usage Pattern**:
```bash
# Initialize secrets for project
dotnet user-secrets init --project src/Api

# Set secret
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=(localdb)\\mssqllocaldb;Database=Stitches;Trusted_Connection=True"

# List secrets (for debugging)
dotnet user-secrets list --project src/Api
```

**Alternatives Considered**:
- `.env` files: Risk of accidental commit, not standard in .NET ecosystem
- Hardcoded placeholders: Requires manual replacement, error-prone
- **Rejected because**: User Secrets is the .NET Core standard for local dev secrets

---

## Azure Infrastructure

### Decision: Bicep Module Patterns

**Rationale**:
- Bicep: Native Azure IaC language, simpler syntax than ARM templates
- Modules: Reusable resource definitions (e.g., app-service.bicep)
- Parameters: Environment-specific values (dev.parameters.json, prod.parameters.json)
- Outputs: Resource IDs and connection strings for pipeline integration

**Module Pattern**:
```bicep
// modules/app-service.bicep
param location string
param environmentName string
param sku string = 'B1'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-stitches-${environmentName}'
  location: location
  sku: {
    name: sku
    capacity: environmentName == 'prod' ? 2 : 1
  }
}

output appServicePlanId string = appServicePlan.id
```

**Alternatives Considered**:
- Terraform: Multi-cloud but adds complexity for Azure-only project
- ARM templates: More verbose, harder to read than Bicep
- Azure Portal (manual): Not reproducible, no version control
- **Rejected because**: Bicep is Azure-native and Constitution-mandated

---

### Decision: Azure App Service Configuration

**Rationale**:
- Hosting: Deploy React SPA (static files) + ASP.NET Core API (same App Service)
- React SPA served from `wwwroot` folder in ASP.NET Core project
- Fallback routing: SPA routes handled by React Router, not server
- Environment variables: Set in App Service configuration, loaded from Key Vault

**Deployment Structure**:
```
App Service (stitches-staging)
├── /wwwroot/           # React SPA build output (dist/)
│   ├── index.html
│   └── assets/
└── /                   # ASP.NET Core API
    └── api/            # API routes
```

**Alternatives Considered**:
- Separate App Services: Higher cost, more complex CORS setup
- Azure Static Web Apps: Doesn't support ASP.NET Core API hosting
- **Rejected because**: Single App Service reduces cost and simplifies deployment for MVP

---

### Decision: Managed Identity for Key Vault Access

**Rationale**:
- No connection strings or credentials in code
- System-assigned identity: Automatically created with App Service
- Key Vault access policy: Grant App Service identity "Get Secrets" permission
- Configuration: `Azure.Identity` library automatically discovers Managed Identity

**Configuration Pattern**:
```csharp
// Program.cs
var keyVaultUrl = builder.Configuration["KeyVaultUrl"];
var client = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
var secretBundle = await client.GetSecretAsync("DatabaseConnectionString");
builder.Configuration["ConnectionStrings:Default"] = secretBundle.Value.Value;
```

**Alternatives Considered**:
- Service Principal: Requires secret management (defeats Key Vault purpose)
- Connection strings in environment: Risk of exposure in logs
- **Rejected because**: Managed Identity is most secure Azure-native approach

---

### Decision: Application Insights Integration

**Rationale**:
- SDK auto-instrumentation: Captures HTTP requests, dependencies, exceptions
- Custom telemetry: Log deployment events, migration status, health checks
- Alerts: Configure for availability, latency, error rate per Constitution
- Correlation: Distributed tracing across frontend → backend → database

**Integration Pattern**:
```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
});
```

**Alternatives Considered**:
- Custom logging: Requires building dashboard and alerting from scratch
- Third-party APM: Additional cost, vendor lock-in
- **Rejected because**: Application Insights is Constitution-mandated Azure service

---

### Decision: Azure SQL Database Connection Patterns

**Rationale**:
- Development: LocalDB (no connection string, Trusted_Connection=True)
- Staging/Prod: Azure SQL Database with Key Vault connection string
- Connection pooling: Default in EF Core, handles 1000+ concurrent requests
- Retry policy: EF Core's EnableRetryOnFailure for transient errors

**Connection String Pattern**:
```json
// appsettings.Development.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=Stitches;Trusted_Connection=True"
  }
}

// Key Vault secret (staging/prod)
{
  "Name": "DatabaseConnectionString",
  "Value": "Server=tcp:stitches-sql.database.windows.net,1433;Database=Stitches;Authentication=Active Directory Managed Identity;Encrypt=True;"
}
```

**Alternatives Considered**:
- SQL Authentication: Requires password management
- Azure AD User Authentication: Doesn't work for App Service identity
- **Rejected because**: Managed Identity authentication is most secure for App Service

---

## CI/CD Pipeline

### Decision: GitHub Actions Multi-Stage Deployment

**Rationale**:
- YAML-based workflows in `.github/workflows/`
- Matrix strategy: Run tests across Node.js 20 + .NET 10
- Artifact caching: Reduce build time (npm cache, NuGet cache)
- Environment secrets: Store Azure credentials securely
- Manual approval: Production deployment requires team review

**Workflow Structure**:
```yaml
# .github/workflows/deploy-staging.yml
name: Deploy to Staging
on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test Frontend
        run: cd frontend && npm ci && npm test
      - name: Test Backend
        run: cd backend && dotnet test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Frontend
        run: cd frontend && npm run build
      - name: Publish Backend
        run: cd backend && dotnet publish -c Release
      - name: Deploy to Azure
        uses: azure/webapps-deploy@v2
```

**Alternatives Considered**:
- Azure DevOps: More Azure-native but adds another tool to learn
- Jenkins: Self-hosted overhead, not cloud-native
- **Rejected because**: GitHub Actions integrates with repository, no additional cost

---

### Decision: Azure Deployment Credentials

**Rationale**:
- Service Principal: Created via `az ad sp create-for-rbac`
- Stored in GitHub Secrets: `AZURE_CREDENTIALS` (JSON format)
- Scoped to Resource Group: Follows principle of least privilege
- Automatic login: `azure/login@v1` action handles authentication

**Credential Setup**:
```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-stitches-deploy" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/stitches-staging \
  --sdk-auth
```

**Alternatives Considered**:
- OpenID Connect (OIDC): More secure but requires additional Azure AD setup
- Personal Access Token: Not suitable for production deployments
- **Rejected because**: Service Principal is standard for MVP, OIDC planned for v1.1

---

### Decision: Database Migration Automation

**Rationale**:
- EF Core migrations run before app deployment
- SQL script generation: Review changes in PR
- Rollback capability: Keep previous migration history
- Idempotent: Safely re-run migrations (checks __EFMigrationsHistory table)

**Pipeline Step**:
```yaml
- name: Run Migrations
  run: |
    cd backend
    dotnet ef database update --project src/Infrastructure --connection "${{ secrets.DB_CONNECTION_STRING }}"
```

**Alternatives Considered**:
- Manual migrations: Error-prone, slows deployment
- Database project (SSDT): Requires SQL Server tooling, heavier process
- **Rejected because**: EF Core migrations integrate with existing ORM, code-first workflow

---

### Decision: Smoke Test Post-Deployment

**Rationale**:
- Verify deployment success: Call health endpoint after deploy
- Fail fast: Rollback if smoke test fails
- 30-second timeout: Per Constitution requirement
- Logs captured: Debugging if test fails

**Smoke Test Script**:
```bash
#!/bin/bash
# scripts/smoke-test.sh
ENDPOINT=$1
TIMEOUT=30

response=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT $ENDPOINT/api/health)

if [ "$response" -eq 200 ]; then
  echo "✅ Smoke test passed"
  exit 0
else
  echo "❌ Smoke test failed: HTTP $response"
  exit 1
fi
```

**Alternatives Considered**:
- Full E2E tests: Too slow for smoke test (30s limit)
- No verification: Risk of deploying broken code
- **Rejected because**: Health check is sufficient for deployment verification, detailed tests run pre-deploy

---

### Decision: Secret Masking in GitHub Actions

**Rationale**:
- Automatic masking: GitHub masks any value stored in Secrets
- Custom masking: Use `::add-mask::` for runtime-generated secrets
- Avoid echo: Never log secrets directly, even during debugging

**Masking Pattern**:
```yaml
- name: Deploy
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  run: |
    echo "::add-mask::$DB_PASSWORD"
    # Password is now masked in logs
```

**Alternatives Considered**:
- Manual log scrubbing: Error-prone, reactive instead of proactive
- No logging: Makes debugging harder
- **Rejected because**: GitHub's built-in masking is automatic and reliable

---

## Summary

All technology choices documented with rationale and alternatives. No "NEEDS CLARIFICATION" markers remain. Ready for Phase 1 design (data models and API contracts).

**Key Decisions**:
- Frontend: React 18 + Vite 5 + TypeScript + Vitest
- Backend: ASP.NET Core 10 + xUnit + NSubstitute + EF Core
- Infrastructure: Bicep + Managed Identity + Application Insights
- CI/CD: GitHub Actions + Service Principal + EF Migrations
