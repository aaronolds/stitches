# Feature Specification: Infrastructure Setup

**Feature Branch**: `001-infrastructure-setup`  
**Created**: January 31, 2026  
**Status**: Draft  
**Input**: User description: "Establish foundational development and deployment infrastructure for the Stitches application including local development environment setup for both frontend (React + Vite) and backend (ASP.NET Core 10+), and Azure cloud infrastructure provisioning with CI/CD automation"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Frontend Development Environment Setup (Priority: P1)

As a frontend developer, I need a fully configured React + Vite development environment running locally so that I can develop UI components and interact with the backend API without any setup friction.

**Why this priority**: This is the foundation for all frontend development. Without a working local environment, no UI work can begin. Frontend development can proceed in parallel with backend work once this is complete.

**Independent Test**: Clone the repository, run `cd frontend && npm install && npm run dev`, navigate to `http://localhost:5173`, and verify the React welcome page loads with no console errors. The development server should support hot module replacement (HMR) for instant updates.

**Acceptance Scenarios**:

1. **Given** the repository is cloned, **When** a developer runs `npm install && npm run dev` in the frontend directory, **Then** the development server starts on `http://localhost:5173` without errors
2. **Given** the development server is running, **When** a developer modifies a React component file, **Then** the changes appear in the browser within 1 second without manual refresh
3. **Given** the frontend project is initialized, **When** a developer runs `npm test`, **Then** the test suite executes successfully with example tests passing
4. **Given** the frontend project has environment variables configured, **When** the application loads, **Then** it correctly reads `VITE_API_URL` to connect to the local backend at `http://localhost:5000`

---

### User Story 2 - Backend API Development Environment Setup (Priority: P1)

As a backend developer, I need a fully configured ASP.NET Core 10+ API running locally with database connectivity so that I can develop REST endpoints, integrate with Azure services, and test business logic without deployment overhead.

**Why this priority**: This is the foundation for all backend development and API creation. Backend and frontend development can proceed in parallel once both local environments are ready. The backend must be ready before any database migrations or Azure service integrations can be implemented.

**Independent Test**: Clone the repository, run `cd backend && dotnet restore && dotnet run`, navigate to `http://localhost:5000/swagger`, and verify the Swagger UI displays with at least a health endpoint documented. The health endpoint at `/api/health` should return `200 OK` when called.

**Acceptance Scenarios**:

1. **Given** the repository is cloned, **When** a developer runs `dotnet restore && dotnet run` in the backend directory, **Then** the API server starts on `http://localhost:5000` and responds to health checks with `200 OK`
2. **Given** the backend API is running, **When** a developer navigates to `/swagger`, **Then** the Swagger UI displays all available endpoints with documentation
3. **Given** the backend project is initialized, **When** a developer runs `dotnet test`, **Then** the test suite executes successfully with example controller tests passing
4. **Given** database configuration is set up, **When** a developer runs `dotnet ef database update`, **Then** migrations execute successfully against the local database
5. **Given** the local database is migrated, **When** the API starts, **Then** it successfully connects to the database and seeds test data

---

### User Story 3 - Azure Cloud Infrastructure Provisioning (Priority: P2)

As a DevOps engineer or developer, I need Azure infrastructure provisioned automatically via Infrastructure as Code with a working CI/CD pipeline so that the application can be deployed to staging and production environments reliably and consistently.

**Why this priority**: While critical for deployment, this can be set up after local development environments are working. This enables the team to deploy completed features to cloud environments and share progress with stakeholders. Without this, the application remains local-only.

**Independent Test**: Run the IaC provisioning command (e.g., `az deployment group create --resource-group stitches-staging --template-file infrastructure/bicep/main.bicep`), verify all Azure resources are created in the Azure portal (App Service, SQL Database, Blob Storage, Key Vault, Application Insights, CDN), then trigger the CI/CD pipeline and verify it successfully deploys the application to staging with the health check endpoint returning `200 OK`.

**Acceptance Scenarios**:

1. **Given** IaC templates are configured, **When** a DevOps engineer runs the provisioning command for staging, **Then** all required Azure resources are created (App Service, SQL Database, Blob Storage, Key Vault, Application Insights, CDN) without errors
2. **Given** Azure infrastructure is provisioned, **When** the CI/CD pipeline is triggered by a push to main branch, **Then** the pipeline builds, tests, and deploys the application to staging within 10 minutes
3. **Given** the application is deployed to staging, **When** the deployment completes, **Then** automated smoke tests verify the health endpoint is accessible and responding correctly
4. **Given** database migrations are pending, **When** the deployment pipeline runs, **Then** EF Core migrations execute automatically before the new application version starts
5. **Given** the application is running in staging, **When** Application Insights is checked, **Then** telemetry data (requests, dependencies, traces) is being received and displayed
6. **Given** secrets are required for the application, **When** the application starts in Azure, **Then** it retrieves all secrets from Key Vault using Managed Identity without exposing credentials in code or logs (including database connection string, JWT signing key, and OAuth client secret placeholder)

---

### Edge Cases

- **What happens when a developer is using an M1/M2 Mac?** Docker images (if used) must support ARM architecture, and platform-specific setup steps must be documented for silicon Macs
- **What happens when Node.js or .NET SDK versions drift?** Lock Node version in `.nvmrc` file and document the required .NET 10+ SDK version in README files to ensure consistency
- **What about HTTPS for local development vs cloud?** Local development uses HTTP (localhost:5000, localhost:5173) for simplicity and no certificate requirements. All cloud deployments (dev, staging, prod) enforce HTTPS-only via Azure App Service configuration with automatic SSL/TLS certificates
- **What happens if Azure Key Vault access is denied?** Document troubleshooting steps for Managed Identity authorization issues, including how to verify role assignments and access policies
- **What happens if a database migration fails during deployment?** The CI/CD pipeline must halt deployment immediately, preserve the previous version, and alert the team via configured notification channels
- **What happens if CI/CD tests fail?** The pipeline must fail and block deployment, preventing broken code from reaching staging or production environments
- **What happens if the chosen Azure region has an outage?** For MVP, accept single-region risk as documented in SDD; multi-region failover is deferred to v1.1
- **What happens if Azure costs exceed budget?** Azure Cost Management alerts should trigger at $500/month threshold to notify the team before costs become problematic
- **How does the system handle long-running CI/CD builds?** Set reasonable pipeline timeout (e.g., 15 minutes) to prevent hung processes from blocking the deployment queue
- **What happens if secrets appear in CI/CD logs?** The pipeline must be configured to mask all secrets in output to prevent credential exposure

## Requirements *(mandatory)*

### Functional Requirements

**Frontend Development Environment:**

- **FR-001**: System MUST provide a React + Vite project structure in a `frontend/` directory with TypeScript configuration and hot module replacement (HMR) capability
- **FR-002**: System MUST include a development server that starts via `npm run dev` and serves the application on `http://localhost:5173`
- **FR-003**: System MUST configure Vitest as the testing framework with at least one example component test that passes
- **FR-004**: System MUST configure ESLint for React best practices and Prettier for code formatting with pre-commit hooks
- **FR-005**: System MUST provide environment variable configuration via `.env.local` with `VITE_API_URL` pointing to the local backend at `http://localhost:5000`
- **FR-006**: System MUST include a `frontend/README.md` with setup instructions, prerequisites (Node.js version), and commands for dev, build, test, and lint

**Backend Development Environment:**

- **FR-007**: System MUST provide an ASP.NET Core 10+ Web API project in a `backend/` directory with a layered architecture structure (API, Application, Domain, Infrastructure layers)
- **FR-008**: System MUST include a development server that starts via `dotnet run` and serves the API on `http://localhost:5000` with a health endpoint at `/api/health`
- **FR-009**: System MUST configure Swagger UI accessible at `/swagger` for API documentation and testing
- **FR-010**: System MUST configure xUnit as the testing framework and NSubstitute for mocking with at least one example controller test that passes
- **FR-011**: System MUST configure database connectivity to Azure SQL Database emulator or SQL Server LocalDB with connection strings in `appsettings.Development.json`
- **FR-012**: System MUST support Entity Framework Core migrations via `dotnet ef database update` command with test data seeding capability
- **FR-013**: System MUST configure `.editorconfig` for C# style rules with code analyzer warnings set to errors
- **FR-014**: System MUST store no secrets in configuration files and document the use of User Secrets for local development in `backend/README.md`

**Azure Infrastructure as Code:**

- **FR-015**: System MUST provide Infrastructure as Code templates (Bicep) in an `infrastructure/` directory that provision all required Azure resources
- **FR-016**: System MUST provision an Azure App Service with App Service Plan configured for at least 2 instances in production and 1 instance in staging
- **FR-017**: System MUST provision an Azure SQL Database with zone-redundant backup configured for production
- **FR-018**: System MUST provision Azure Blob Storage with RA-GRS geo-replication configured for production
- **FR-019**: System MUST provision Azure Key Vault for secrets management with Managed Identity access configured for App Service
- **FR-020**: System MUST provision Application Insights for application monitoring and telemetry collection
- **FR-021**: System MUST provision Azure CDN for static asset delivery in production
- **FR-022**: System MUST support parameterized infrastructure deployment for multiple environments (dev, staging, prod) with environment-specific configuration

**Secrets Management:**

- **FR-023**: Azure Key Vault MUST store database connection strings, blob storage account keys, OAuth client secrets, and JWT signing keys (OAuth client secret created as placeholder for Feature 1 integration)
- **FR-024**: System MUST inject secrets at application runtime via Managed Identity without storing them in code or configuration files
- **FR-025**: System MUST never expose secrets in CI/CD pipeline logs or error messages

**CI/CD Pipeline:**

- **FR-026**: System MUST provide a CI/CD pipeline configuration (GitHub Actions or Azure DevOps) that triggers on push to main branch for staging deployment and requires manual approval for production deployment
- **FR-027**: Pipeline MUST execute all tests (frontend Vitest + backend xUnit) and fail the build if any tests fail
- **FR-028**: Pipeline MUST build frontend artifacts (React bundle) and backend artifacts (.NET publish output)
- **FR-029**: Pipeline MUST provision or update Azure infrastructure using IaC templates before deploying application code
- **FR-030**: Pipeline MUST deploy application artifacts to Azure App Service after successful infrastructure provisioning
- **FR-031**: Pipeline MUST execute Entity Framework Core database migrations automatically during deployment with rollback capability on failure
- **FR-032**: Pipeline MUST run automated smoke tests post-deployment to verify the health endpoint is accessible
- **FR-033**: Pipeline MUST complete staging deployment within 10 minutes from trigger to completion

**Monitoring and Alerts:**

- **FR-034**: System MUST configure Application Insights alerts for availability dropping below 99.5% monthly
- **FR-035**: System MUST configure Application Insights alerts for API latency exceeding 500ms at p95 percentile
- **FR-036**: System MUST configure Application Insights alerts for error rate exceeding 1%
- **FR-037**: System MUST send alert notifications to the team via configured channels (email or Slack)
- **FR-038**: System MUST configure Azure Cost Management alerts at $500/month threshold (Note: Azure Cost Management budgets cannot be provisioned via Bicep; requires manual Azure CLI or portal configuration as documented in runbooks)

**Documentation:**

- **FR-039**: System MUST provide `infrastructure/README.md` with provisioning instructions, manual deployment steps for disaster recovery, and secrets rotation procedures
- **FR-040**: System MUST provide a runbook for common failure scenarios including migration rollback, Key Vault access issues, and pipeline failures

### Key Entities *(include if feature involves data)*

- **Environment Configuration**: Represents environment-specific settings (dev, staging, prod) including resource tier, scaling configuration, backup strategy, and monitoring thresholds
- **Infrastructure Resource**: Represents an Azure resource provisioned via IaC with properties including resource type, name, region, configuration parameters, and relationships to other resources
- **Build Artifact**: Represents compiled application code ready for deployment including frontend bundle and backend publish output with version metadata
- **Deployment**: Represents a single deployment operation with properties including environment target, timestamp, build artifacts, migration status, and health check results
- **Secret**: Represents sensitive configuration stored in Key Vault including secret name, value (never exposed in logs), rotation schedule, and access audit trail

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can clone the repository and run the frontend development server successfully within 5 minutes of setup completion
- **SC-002**: Developers can clone the repository and run the backend API successfully within 5 minutes of setup completion with health endpoint responding correctly
- **SC-003**: Frontend hot module replacement (HMR) reflects code changes in the browser within 1 second
- **SC-004**: Local backend API health endpoint responds in under 50 milliseconds
- **SC-005**: Azure infrastructure provisioning completes successfully for staging environment without manual intervention
- **SC-006**: CI/CD pipeline deploys application to staging environment within 10 minutes from commit to main branch
- **SC-007**: Automated smoke tests verify deployment health within 30 seconds post-deployment
- **SC-008**: Application Insights successfully receives and displays telemetry data (requests, dependencies, traces) from staging environment
- **SC-009**: Zero secrets are exposed in repository code, configuration files, or CI/CD pipeline logs
- **SC-010**: Developer onboarding documentation is complete and enables a new team member to set up local environments without assistance
- **SC-011**: All unit tests (frontend and backend) pass successfully in local and CI/CD environments
- **SC-012**: Database migrations execute successfully during deployment with rollback capability verified
