# Stitches Development Guidelines

Auto-generated from feature plans. Last updated: 2026-01-31

## Project Overview

Stitches is a cloud-first photo-to-cross-stitch pattern conversion web application built with React frontend and ASP.NET Core backend, deployed on Azure.

## Active Technologies

### Frontend (Feature 001-infrastructure-setup)
- React 19+ with TypeScript
- Vite 5+ (build tool with HMR)
- Vitest (testing framework)
- ESLint + Prettier (code quality)
- React Router (navigation)
- Context API or Redux (state management)

### Backend (Feature 001-infrastructure-setup)
- ASP.NET Core 10+ (C# Web API)
- Entity Framework Core (ORM)
- xUnit + NSubstitute (testing and mocking)
- Swagger/Swashbuckle (API documentation)
- Azure SDK libraries

### Infrastructure (Feature 001-infrastructure-setup)
- Azure App Service (hosting)
- Azure SQL Database (data storage)
- Azure Blob Storage (file storage)
- Azure Key Vault (secrets management)
- Azure Application Insights (monitoring)
- Azure CDN (content delivery)
- Bicep (Infrastructure as Code)
- GitHub Actions (CI/CD)

## Project Structure

```text
frontend/
├── src/
│   ├── components/      # Reusable UI components
│   ├── pages/           # Page-level components
│   ├── services/        # API client and business logic
│   └── styles/          # Global styles and theme
└── tests/

backend/
├── src/
│   ├── Api/             # Controllers, Program.cs (HTTP layer)
│   ├── Application/     # Use cases and business logic
│   ├── Domain/          # Entities, value objects
│   └── Infrastructure/  # Data access, Azure clients
└── tests/

infrastructure/
├── bicep/               # Azure resource templates
└── scripts/             # Deployment and migration scripts

.github/
└── workflows/           # CI/CD pipelines
```

## Development Commands

### Frontend
```bash
cd frontend
npm install              # Install dependencies
npm run dev              # Start dev server (localhost:5173)
npm test                 # Run unit tests
npm run build            # Build for production
npm run lint             # Run ESLint
```

### Backend
```bash
cd backend
dotnet restore           # Restore NuGet packages
dotnet run --project src/Api  # Start API (localhost:5000)
dotnet test              # Run unit tests
dotnet ef database update --project src/Infrastructure  # Apply migrations
dotnet ef migrations add [Name] --project src/Infrastructure  # Create migration
```

## Code Style

### Frontend (TypeScript/React)
- Use functional components with hooks
- Prefer TypeScript strict mode
- Use ESLint + Prettier for formatting
- Name files: PascalCase for components (Button.tsx), camelCase for utilities (apiClient.ts)
- Test files: ComponentName.test.tsx pattern

### Backend (C#)
- Follow layered architecture: API → Application → Domain → Infrastructure
- Use dependency injection for all services
- Async/await for all I/O operations
- Name files: PascalCase for classes (HealthController.cs)
- Test files: ClassNameTests.cs pattern
- Use xUnit + NSubstitute for testing (per Constitution v1.1.1)

## Security Guidelines

- **NEVER** commit secrets (connection strings, API keys, passwords)
- **ALWAYS** use Azure Key Vault for secrets in staging/production
- **ALWAYS** use User Secrets for local development (.NET)
- **ALWAYS** use .env.local for local development (Vite, gitignored)
- **NEVER** log sensitive data (PII, passwords, tokens)
- **ALWAYS** use Managed Identity for Azure service authentication

## Performance Targets

- Frontend HMR: < 1 second
- Backend health check: < 50 ms (local), < 200 ms (cloud)
- API latency (p95): < 500 ms (per Constitution)
- Canvas rendering: 60 FPS
- CI/CD deployment: < 10 minutes

## Constitution Compliance

All code must comply with `.specify/memory/constitution.md`:
- Cloud-First Architecture (Azure-native)
- Security & Privacy-First (Key Vault, no secrets in code)
- Performance-First Design (SLO targets)
- Accessibility & Simplicity (web-first, OAuth-only auth)
- User-Centric Quality (beta testing, A/B testing)

## Recent Changes

- 001-infrastructure-setup: Added frontend (React + Vite), backend (ASP.NET Core), Azure infrastructure (Bicep), and CI/CD (GitHub Actions)

<!-- MANUAL ADDITIONS START -->
<!-- Add custom instructions below this line. They will be preserved during updates. -->

<!-- MANUAL ADDITIONS END -->
