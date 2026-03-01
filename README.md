# Stitches

A cloud-first photo-to-cross-stitch pattern conversion web application.

## Overview

Stitches enables users to convert photos into cross-stitch patterns with an intuitive web interface. Built with React frontend and ASP.NET Core backend, deployed on Azure.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AZURE CLOUD                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────────────────────────────────────────┐   │
│  │   Azure CDN  │    │              Azure App Service                   │   │
│  │   (Static)   │    │  ┌────────────┐  ┌────────────┐  ┌────────────┐ │   │
│  │              │    │  │    API     │──│ Application│──│   Domain   │ │   │
│  │  React SPA   │────│  │ Controllers│  │   Layer    │  │   Layer    │ │   │
│  │              │    │  └────────────┘  └────────────┘  └──────┬─────┘ │   │
│  └──────────────┘    │                                        │        │   │
│                      │  ┌──────────────────────────────────────┘        │   │
│                      │  │ Infrastructure Layer (EF Core)               │   │
│                      │  └──────────────┬───────────────────────────────┘   │
│                      └─────────────────┼───────────────────────────────────┘   │
│                                        │                                     │
│  ┌──────────────┐  ┌──────────────┐   │   ┌──────────────┐                   │
│  │  Key Vault   │  │ App Insights │   │   │    Azure     │                   │
│  │  (Secrets)   │  │ (Telemetry)  │   └──>│ SQL Database │                   │
│  └──────────────┘  └──────────────┘       └──────────────┘                   │
│                                                                              │
│  ┌──────────────┐                                                            │
│  │ Blob Storage │                                                            │
│  │   (Files)    │                                                            │
│  └──────────────┘                                                            │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

           │                    │
           │  GitHub Actions    │
           │  (CI/CD Pipeline)  │
           └────────────────────┘
```

### Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 19+, TypeScript, Vite |
| Backend | ASP.NET Core 10+, C#, EF Core |
| Database | Azure SQL Database |
| Storage | Azure Blob Storage |
| Auth | Azure AD B2C (OAuth 2.0) |
| Monitoring | Azure Application Insights |
| IaC | Azure Bicep |
| CI/CD | GitHub Actions |

## Quick Start

### Prerequisites

| Software | Minimum Version | Verification Command |
|----------|----------------|---------------------|
| **Git** | 2.30+ | `git --version` |
| **Node.js** | 20.0+ | `node --version` |
| **npm** | 10.0+ | `npm --version` |
| **.NET SDK** | 10.0+ | `dotnet --version` |

### Setup

```bash
# Clone the repository
git clone https://github.com/aaronolds/stitches.git
cd stitches
```

### Frontend Development

```bash
cd frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) to view the application.

### Backend Development

```bash
cd backend
dotnet restore
dotnet run --project src/Api
```

Open [http://localhost:5000/swagger](http://localhost:5000/swagger) to view API documentation.

### Build Script

A unified build script is available at the repo root:

```bash
./build.sh              # Build frontend and backend (default)
./build.sh frontend     # Build frontend only
./build.sh backend      # Build backend only
./build.sh --help       # Show usage information
```

The script installs dependencies, runs production builds, reports elapsed time for each step, and exits with a non-zero code on failure.

### Dev Script

A dev script starts development servers with HMR and live reload:

```bash
./dev.sh                # Start both frontend and backend concurrently (default)
./dev.sh frontend       # Start frontend only (Vite HMR on localhost:5173)
./dev.sh backend        # Start backend only (ASP.NET Core on localhost:5000)
./dev.sh --help         # Show usage information
```

When running both servers, output is prefixed with `[frontend]` / `[backend]` labels. Press **Ctrl+C** to stop all servers cleanly.

| Server | URL |
|--------|-----|
| Frontend | [http://localhost:5173](http://localhost:5173) |
| Backend API | [http://localhost:5000](http://localhost:5000) |
| Swagger UI | [http://localhost:5000/swagger](http://localhost:5000/swagger) |

## Project Structure

```text
frontend/           # React + Vite + TypeScript
backend/            # ASP.NET Core 10+ Web API
infrastructure/     # Azure Bicep IaC templates
.github/workflows/  # CI/CD pipelines
docs/               # Documentation
specs/              # Feature specifications
```

## Development Commands

### Frontend

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm test` | Run tests |
| `npm run lint` | Run ESLint |

### Backend

| Command | Description |
|---------|-------------|
| `dotnet run --project src/Api` | Start API server |
| `dotnet test` | Run tests |
| `dotnet ef database update` | Apply migrations |

## Documentation

- [Frontend README](frontend/README.md)
- [Backend README](backend/README.md)
- [Infrastructure README](infrastructure/README.md)
- [Quickstart Guide](specs/001-infrastructure-setup/quickstart.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

Proprietary - All rights reserved.

---

**Version**: 0.1.0 | **Last Updated**: 2026-01-31
