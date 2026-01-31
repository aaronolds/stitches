# Implementation Plan: Infrastructure Setup

**Branch**: `001-infrastructure-setup` | **Date**: 2026-01-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-infrastructure-setup/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Establish foundational development and deployment infrastructure for the Stitches application. This includes:

1. **Frontend Development Environment**: React + Vite project with TypeScript, Vitest testing, ESLint/Prettier, and HMR capability running on `localhost:5173`
2. **Backend API Environment**: ASP.NET Core 10+ Web API with layered architecture, xUnit/NSubstitute testing, Swagger documentation, EF Core migrations, and SQL Server LocalDB running on `localhost:5000`
3. **Azure Cloud Infrastructure**: Infrastructure as Code (Bicep) provisioning App Service, SQL Database, Blob Storage, Key Vault, Application Insights, and CDN with CI/CD pipeline (GitHub Actions) for automated deployment to staging and production

**Technical Approach**: Web application with separate frontend and backend projects, local development with database emulation, cloud deployment via IaC templates, and automated CI/CD with test gates and smoke tests.

## Technical Context

**Language/Version**: 
- Frontend: JavaScript/TypeScript (Node.js 20+)
- Backend: C# (ASP.NET Core 10+, .NET 10 SDK)

**Primary Dependencies**: 
- Frontend: React 18+, Vite 5+, Vitest, ESLint, Prettier, React Router
- Backend: ASP.NET Core Web API, Entity Framework Core, xUnit, NSubstitute, Swashbuckle (Swagger)
- Infrastructure: Azure CLI, Bicep templates
- CI/CD: GitHub Actions

**Storage**: 
- Local Dev: SQL Server LocalDB or Azure SQL Database Emulator
- Staging/Prod: Azure SQL Database (zone-redundant in prod)
- Blob Storage: Azure Blob Storage (RA-GRS in prod)

**Testing**: 
- Frontend: Vitest (unit tests, component tests)
- Backend: xUnit (unit tests, integration tests), NSubstitute (mocking)
- CI/CD: Automated test execution in pipeline, smoke tests post-deployment

**Target Platform**: 
- Frontend: Modern browsers (desktop and mobile PWA), React SPA
- Backend: Azure App Service (Linux or Windows container)
- Database: Azure SQL Database
- CDN: Azure CDN

**Project Type**: Web application (separate frontend React SPA + backend REST API)

**Performance Goals**: 
- Frontend HMR: < 1 second
- Local backend health check: < 50 ms
- CI/CD deployment: < 10 minutes (staging)
- Smoke tests: < 30 seconds

**Constraints**: 
- Zero secrets in code, configuration files, or logs
- All Azure resources provisioned via IaC
- Tests must pass before deployment
- Database migrations must be automatic and rollback-capable
- Deployment pipeline must be idempotent

**Scale/Scope**: 
- 2 local development environments (frontend + backend)
- 3 cloud environments (dev, staging, prod)
- 8 Azure resource types to provision
- 40 functional requirements across 3 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Evaluation

| Principle | Status | Evaluation |
|-----------|--------|------------|
| **I. Cloud-First Architecture** | ✅ PASS | All mandatory Azure services provisioned (App Service, SQL Database, Blob Storage). IaC ensures infrastructure reproducibility. Autosave and cloud persistence infrastructure will be foundation for Feature 1+. |
| **II. Accessibility & Simplicity** | ✅ PASS | React SPA with Vite ensures modern browser compatibility. Foundation for PWA. OAuth infrastructure prepared (Key Vault ready for client secrets). Developer documentation (README files) ensures low-barrier onboarding. |
| **III. User-Centric Quality** | ✅ PASS | Infrastructure enables beta testing in staging environment before production. CI/CD pipeline gates ensure quality (tests must pass). Application Insights provides telemetry for user behavior analysis in later features. |
| **IV. Security & Privacy-First** | ✅ PASS | Azure Key Vault configured for all secrets. Managed Identity prevents credential exposure. No secrets in code or logs (enforced in CI/CD). HTTPS mandatory via App Service. Foundation for OAuth and JWT validation in Feature 1. |
| **V. Performance-First Design** | ✅ PASS | Local dev performance targets defined (HMR < 1s, health check < 50ms). Application Insights monitoring configured with alerts for latency, availability, and errors. CDN infrastructure ready for React bundle caching. |

### Mandatory Tech Stack Compliance

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| Frontend: React + Vite | ✅ PASS | React 18+ with Vite 5+ build tool, Context API or Redux for state |
| Backend: ASP.NET Core 10+ | ✅ PASS | ASP.NET Core 10+ Web API with C#, REST API architecture |
| Database: Azure SQL Database | ✅ PASS | Provisioned with zone-redundant backup in prod, LocalDB for local dev |
| Storage: Azure Blob Storage | ✅ PASS | Provisioned with RA-GRS geo-replication in prod |
| Auth: OAuth 2.0 | ✅ PASS | Infrastructure ready (Key Vault for secrets), OAuth implementation in Feature 1 |
| Secrets: Azure Key Vault | ✅ PASS | Provisioned with Managed Identity access for App Service |
| Compute: Azure App Service | ✅ PASS | Provisioned with 2+ instances in prod for HA |
| CDN: Azure CDN | ✅ PASS | Provisioned for static asset delivery |
| Testing: Vitest + xUnit + NSubstitute | ✅ PASS | Vitest for frontend, xUnit + NSubstitute for backend per Constitution v1.1.1 |
| Deployment: IaC + CI/CD | ✅ PASS | Bicep templates for IaC, GitHub Actions for CI/CD pipeline |

### Architecture & Governance Compliance

| Requirement | Status | Evaluation |
|-------------|--------|------------|
| Single Region (MVP) | ✅ PASS | Azure resources deployed to single region (East US), multi-region deferred to v1.1 |
| Environment Variables | ✅ PASS | Key Vault injection at runtime, no secrets in `.env` files or code |
| Monitoring & Alerting | ✅ PASS | Application Insights with alerts for availability (99.5%), latency (500ms p95), error rate (1%) |
| Development Quality Gates | ✅ PASS | CI/CD pipeline enforces: tests pass, no secrets in code, performance baseline, documentation updated |
| Database Migrations | ✅ PASS | EF Core migrations automated in deployment pipeline with rollback capability |

### Gate Decision

**✅ PASS** - All constitution principles and mandatory requirements satisfied. No violations. No complexity justification required. Proceed to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/001-infrastructure-setup/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── health-check-api.yaml  # OpenAPI spec for initial health endpoint
│   └── app-insights-contract.md  # Expected telemetry schema
├── checklists/          # Quality validation checklists
│   └── requirements.md  # Spec quality checklist (completed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
frontend/
├── src/
│   ├── components/      # Reusable UI components
│   ├── pages/           # Page-level components (routes)
│   ├── services/        # API client, business logic
│   ├── assets/          # Static assets (images, fonts)
│   ├── styles/          # Global styles and theme
│   ├── App.tsx          # Root component
│   └── main.tsx         # Entry point
├── tests/
│   ├── unit/            # Component unit tests
│   └── integration/     # User flow tests
├── public/              # Static assets served as-is
├── .env.local           # Local environment variables (gitignored)
├── .env.example         # Environment variable template
├── package.json         # Dependencies and scripts
├── vite.config.ts       # Vite configuration
├── tsconfig.json        # TypeScript configuration
├── .eslintrc.js         # ESLint configuration
├── .prettierrc          # Prettier configuration
└── README.md            # Frontend setup documentation

backend/
├── src/
│   ├── Api/             # Controllers/Minimal APIs (HTTP layer)
│   │   ├── Controllers/
│   │   │   └── HealthController.cs
│   │   ├── Program.cs   # App entry point, middleware config
│   │   └── Api.csproj
│   ├── Application/     # Use cases and business logic
│   │   ├── Common/
│   │   └── Application.csproj
│   ├── Domain/          # Entities, value objects, domain logic
│   │   ├── Entities/
│   │   └── Domain.csproj
│   └── Infrastructure/  # Data access, Azure clients, external integrations
│       ├── Data/        # EF Core DbContext, migrations
│       ├── Azure/       # Blob Storage, Key Vault clients
│       └── Infrastructure.csproj
├── tests/
│   ├── Api.Tests/       # Controller/endpoint tests
│   ├── Application.Tests/  # Business logic unit tests
│   ├── Domain.Tests/    # Domain model tests
│   └── Integration.Tests/  # End-to-end API tests
├── Stitches.sln         # Solution file
├── appsettings.json     # Shared configuration defaults
├── appsettings.Development.json  # Local dev configuration
├── .editorconfig        # C# style rules
└── README.md            # Backend setup documentation

infrastructure/
├── bicep/
│   ├── main.bicep       # Root IaC template
│   ├── modules/
│   │   ├── app-service.bicep
│   │   ├── sql-database.bicep
│   │   ├── blob-storage.bicep
│   │   ├── key-vault.bicep
│   │   ├── app-insights.bicep
│   │   └── cdn.bicep
│   └── parameters/
│       ├── dev.parameters.json
│       ├── staging.parameters.json
│       └── prod.parameters.json
├── scripts/
│   ├── provision.sh     # IaC deployment script
│   ├── migrate.sh       # Database migration runner
│   └── smoke-test.sh    # Post-deployment verification
└── README.md            # Infrastructure documentation

.github/
├── workflows/
│   ├── deploy-staging.yml    # CI/CD for staging (on push to main)
│   ├── deploy-production.yml # CI/CD for production (manual trigger)
│   └── pr-validation.yml     # Run tests on PRs
└── CODEOWNERS           # Code review assignments

docs/
├── BRD.md               # Business Requirements Document (existing)
├── PRD.md               # Product Requirements Document (existing)
├── SDD.md               # Software Design Document (existing)
└── runbooks/
    ├── deployment-failure.md
    ├── migration-rollback.md
    └── key-vault-access.md
```

**Structure Decision**: Web application with separate frontend and backend projects per Constitution requirements. Frontend is a React SPA built with Vite; backend is an ASP.NET Core Web API with layered architecture (API, Application, Domain, Infrastructure) per SDD Section 8.1. Infrastructure as Code templates organized by resource type in Bicep modules. CI/CD workflows separated by environment (staging vs production) for clear deployment gates.

## Complexity Tracking

**Not Applicable** - No constitution violations detected. All technical choices align with mandatory requirements. No complexity justification needed.

---

## Phase 0: Outline & Research

*This phase resolves all "NEEDS CLARIFICATION" items from Technical Context and researches best practices for chosen technologies.*

### Research Tasks

No "NEEDS CLARIFICATION" markers remain in Technical Context. All technology choices are specified in Constitution. Research tasks focus on implementation best practices:

1. **Frontend Development Setup**
   - Research: Vite configuration best practices for React + TypeScript
   - Research: Vitest setup patterns for component testing
   - Research: ESLint + Prettier integration for React projects
   - Research: Environment variable management in Vite (.env.local patterns)

2. **Backend Development Setup**
   - Research: ASP.NET Core 10+ project structure for layered architecture
   - Research: xUnit + NSubstitute patterns for API testing
   - Research: Swagger/OpenAPI integration in ASP.NET Core
   - Research: EF Core migration workflow and LocalDB configuration
   - Research: User Secrets management for local development

3. **Azure Infrastructure**
   - Research: Bicep module patterns for Azure resource organization
   - Research: Azure App Service configuration for .NET + React hosting
   - Research: Managed Identity setup for Key Vault access from App Service
   - Research: Application Insights integration with ASP.NET Core
   - Research: Azure SQL Database connection string patterns (development vs production)

4. **CI/CD Pipeline**
   - Research: GitHub Actions workflow patterns for multi-stage deployment
   - Research: Azure deployment credentials (service principal vs managed identity)
   - Research: Database migration automation in CI/CD pipelines
   - Research: Smoke test patterns for post-deployment verification
   - Research: Secret masking in GitHub Actions logs

### Research Output

**File**: `research.md`

**Structure**:
```markdown
# Research Findings: Infrastructure Setup

## Frontend Development
### Decision: Vite Configuration
- **Rationale**: [Configuration decisions and why chosen]
- **Alternatives considered**: [Other approaches evaluated]

### Decision: Vitest Setup
- **Rationale**: [...]
- **Alternatives considered**: [...]

[Continue for all frontend tasks]

## Backend Development
[Same structure for backend research tasks]

## Azure Infrastructure
[Same structure for Azure research tasks]

## CI/CD Pipeline
[Same structure for CI/CD research tasks]
```

---

## Phase 1: Design & Contracts

*This phase generates data models and API contracts based on feature requirements and research findings.*

### Phase 1 Tasks

1. **Data Model Design** (`data-model.md`)
   - **Environment Configuration Entity**: Properties include environment name (dev/staging/prod), resource tier, scaling configuration (instance count), backup strategy, monitoring thresholds
   - **Infrastructure Resource Entity**: Properties include resource type (App Service, SQL Database, etc.), name, region, configuration parameters (JSON), relationships to other resources
   - **Deployment Entity**: Properties include environment target, timestamp, build artifacts (frontend bundle path, backend publish path), migration status, health check results, deployment status
   - **Secret Entity**: Properties include secret name, Key Vault reference (not value), rotation schedule, last accessed timestamp

2. **API Contract Design** (`contracts/`)
   - **Health Check API** (`health-check-api.yaml`): OpenAPI specification for `/api/health` endpoint
     - GET `/api/health`: Returns `200 OK` with response body `{ "status": "healthy", "timestamp": "ISO8601" }`
   - **Application Insights Contract** (`app-insights-contract.md`): Expected telemetry schema
     - Request telemetry: HTTP method, path, duration, response code
     - Dependency telemetry: Database queries, blob storage calls
     - Custom events: Deployment started, migration executed, health check failed

3. **Quickstart Guide** (`quickstart.md`)
   - Prerequisites: Node.js 20+, .NET 10 SDK, Azure CLI, Git
   - Frontend setup: Clone → `cd frontend` → `npm install` → `npm run dev`
   - Backend setup: Clone → `cd backend` → `dotnet restore` → `dotnet run`
   - Verification: Frontend at `http://localhost:5173`, Backend Swagger at `http://localhost:5000/swagger`
   - Troubleshooting: Common issues (port conflicts, missing SDKs, database connection errors)

4. **Agent Context Update**
   - Run: `.specify/scripts/bash/update-agent-context.sh copilot`
   - Update GitHub Copilot's instructions with infrastructure technologies
   - Add: React, Vite, ASP.NET Core, Bicep, Azure services context
   - Preserve manual additions between markers

### Phase 1 Outputs

✅ **COMPLETED** (2026-01-31)

- ✅ `data-model.md` - Entity definitions for environment, resource, deployment, secret (completed)
- ✅ `contracts/health-check-api.yaml` - OpenAPI spec for health endpoint (completed)
- ✅ `contracts/app-insights-contract.md` - Telemetry schema documentation (completed)
- ✅ `quickstart.md` - Developer onboarding guide (completed)
- ✅ Agent context updated with infrastructure technologies (completed - `.github/agents/copilot-instructions.md` created)

### Constitution Re-Check (Post-Design)

All Phase 1 designs align with Constitution:
- ✅ Cloud-First: All entities reference Azure resources
- ✅ Security: Secret entity never stores values, only Key Vault references
- ✅ Performance: Health check endpoint designed for < 50ms response
- ✅ Monitoring: Application Insights contract ensures telemetry capture

---

## Phase 2: Implementation Planning

*Phase 2 (task breakdown) is handled by the `/speckit.tasks` command and is NOT part of `/speckit.plan` output.*

**Status**: Plan complete. Ready for `/speckit.tasks` to generate implementation tasks.
