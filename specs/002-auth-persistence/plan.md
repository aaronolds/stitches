# Implementation Plan: Authentication & Persistence Foundation

**Branch**: `002-auth-persistence` | **Date**: 2026-03-03 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-auth-persistence/spec.md`

## Summary

Implement OAuth 2.0 authentication via Microsoft Entra External ID (social providers: Google minimum, stretch: Facebook/Apple/Microsoft), design CRUD API with ownership-based authorization, autosave with 30-second debounce, and draft recovery. Backend uses ASP.NET Core 10+ with Entity Framework Core against Azure SQL Database. Frontend uses React 19+ with MSAL.js for the OAuth flow, React Context for auth state, and a custom autosave hook with debounce/retry logic.

## Technical Context

**Language/Version**: C# / .NET 10 (backend), TypeScript 5.9 / React 19 (frontend)
**Primary Dependencies**: ASP.NET Core 10, Entity Framework Core 10, Microsoft.Identity.Web (backend JWT validation), MSAL.js v2 (frontend OAuth), React Router v7
**Storage**: Azure SQL Database (EF Core), Azure Blob Storage (future image uploads)
**Testing**: xUnit + NSubstitute + FluentAssertions (backend), Vitest + Testing Library (frontend)
**Target Platform**: Web (modern browsers, desktop + mobile PWA)
**Project Type**: Web application (React SPA + ASP.NET Core REST API)
**Performance Goals**: API latency < 200ms (p95), autosave < 2s (p95), page load < 2s (p95)
**Constraints**: < 200ms p95 API, 60 req/min reads + 30 req/min writes per user, tokens in memory only (no localStorage)
**Scale/Scope**: 1000+ designs per user, 100 concurrent users at launch, single Azure region (East US)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| **I. Cloud-First Architecture** | PASS | All designs cloud-persisted via Azure SQL. Autosave every 30s. Offline edits queue in memory for sync. |
| **II. Accessibility & Simplicity** | PASS | OAuth-only login (no passwords). Sign-in wall is minimal. Web-first React SPA. |
| **III. User-Centric Quality** | PASS | 70% first-session completion target (SC-002). Autosave UI feedback. Recently Deleted recovery. |
| **IV. Security & Privacy-First** | PASS | OAuth delegated auth. JWT + userId authorization on every CRUD. Secrets in Key Vault. Tokens in memory only. Rate limiting per user. |
| **V. Performance-First Design** | PASS | API < 200ms p95. Autosave < 2s p95. Pagination on design listing. Rate limiting prevents abuse. |
| **Mandatory Tech Stack** | PASS | React + Vite (frontend), ASP.NET Core 10 (backend), Azure SQL, Key Vault, App Insights. xUnit + NSubstitute (testing). |

**Pre-design gate: PASS** — no violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-persistence/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── Api/
│   │   ├── Controllers/
│   │   │   ├── HealthController.cs        # Existing
│   │   │   ├── AuthController.cs          # NEW: sign-in/sign-out endpoints
│   │   │   └── DesignsController.cs       # NEW: design CRUD + search/sort/filter
│   │   ├── Middleware/
│   │   │   └── RateLimitingMiddleware.cs   # NEW: per-user rate limiting
│   │   ├── Program.cs                     # MODIFY: add auth, EF Core, rate limiting
│   │   └── appsettings.json               # MODIFY: add auth config section
│   ├── Application/
│   │   ├── DTOs/
│   │   │   ├── DesignDto.cs               # NEW: design request/response DTOs
│   │   │   └── UserDto.cs                 # NEW: user profile DTO
│   │   ├── Services/
│   │   │   ├── IDesignService.cs          # NEW: design business logic interface
│   │   │   └── DesignService.cs           # NEW: design business logic
│   │   └── Validators/
│   │       └── DesignValidator.cs         # NEW: title/dimension validation
│   ├── Domain/
│   │   └── Entities/
│   │       ├── User.cs                    # NEW: user entity
│   │       └── Design.cs                  # NEW: design entity
│   └── Infrastructure/
│       ├── Data/
│       │   ├── ApplicationDbContext.cs     # MODIFY: add User + Design DbSets
│       │   └── Migrations/                # NEW: EF Core migrations
│       └── Repositories/
│           ├── IDesignRepository.cs        # NEW: design data access interface
│           └── DesignRepository.cs         # NEW: design data access
└── tests/
    ├── Api.Tests/
    │   ├── DesignsControllerTests.cs      # NEW: controller unit tests
    │   └── AuthControllerTests.cs         # NEW: auth controller tests
    ├── Application.Tests/
    │   └── DesignServiceTests.cs          # NEW: service unit tests
    └── Integration.Tests/
        ├── DesignCrudTests.cs             # NEW: full CRUD integration tests
        └── AuthFlowTests.cs              # NEW: auth flow integration tests

frontend/
├── src/
│   ├── auth/
│   │   ├── AuthProvider.tsx               # NEW: MSAL auth context provider
│   │   ├── AuthGuard.tsx                  # NEW: sign-in wall / route protection
│   │   ├── LoginPage.tsx                  # NEW: OAuth provider buttons
│   │   └── msalConfig.ts                 # NEW: MSAL configuration
│   ├── designs/
│   │   ├── DesignLibrary.tsx              # NEW: design list with search/sort/filter
│   │   ├── DesignCard.tsx                 # NEW: design thumbnail card
│   │   ├── RecentlyDeleted.tsx            # NEW: soft-deleted design recovery
│   │   └── designApi.ts                   # NEW: design CRUD API client
│   ├── autosave/
│   │   ├── useAutosave.ts                 # NEW: autosave hook (debounce + retry)
│   │   └── AutosaveIndicator.tsx          # NEW: saving/saved/error status UI
│   ├── services/
│   │   └── apiClient.ts                   # NEW: authenticated HTTP client
│   ├── App.tsx                            # MODIFY: add routing + auth provider
│   └── main.tsx                           # Existing (no changes)
└── tests/
    └── unit/
        ├── AuthProvider.test.tsx           # NEW
        ├── DesignLibrary.test.tsx          # NEW
        ├── useAutosave.test.ts            # NEW
        └── AutosaveIndicator.test.tsx     # NEW

infrastructure/
├── bicep/
│   ├── main.bicep                         # MODIFY: add Entra External ID params
│   └── modules/
│       └── entra-external-id.bicep        # NEW: Entra External ID tenant config
```

**Structure Decision**: Existing layered architecture (Api → Application → Domain → Infrastructure) is retained. New code follows the established pattern with domain entities in Domain, business logic in Application, data access in Infrastructure, and HTTP concerns in Api. Frontend adds feature-based folders (auth/, designs/, autosave/) under src/.

## Constitution Re-Check (Post-Design)

*GATE: Re-evaluated after Phase 1 design artifacts are complete.*

| Principle | Status | Post-Design Evidence |
|-----------|--------|---------------------|
| **I. Cloud-First Architecture** | PASS | Data model stores all designs in Azure SQL via EF Core. Autosave PATCH endpoint handles 30s debounce saves. Offline edits queue in React state, auto-sync on reconnect. No local-only fallback. |
| **II. Accessibility & Simplicity** | PASS | OAuth-only login via Entra External ID (no passwords). React SPA with MSAL.js. Sign-in wall for unauthenticated users. Web-first, accessible on desktop + mobile. |
| **III. User-Centric Quality** | PASS | Autosave with visual feedback (Saving/Saved/Error). Recently Deleted view with 30-day recovery. Design search/sort/filter for library management. Pagination for large libraries. |
| **IV. Security & Privacy-First** | PASS | JWT bearer auth on every API endpoint. UserId ownership check on every design CRUD operation. Secrets in Key Vault (user secrets for local dev). Tokens in sessionStorage (not localStorage). Rate limiting prevents abuse. Unauthorized access logged. |
| **V. Performance-First Design** | PASS | API < 200ms (p95) achievable with optimized EF Core indexes (composite + filtered). Autosave < 2s (p95) via PATCH endpoint. Pagination prevents large result sets. Background purge job avoids blocking API. |
| **Mandatory Tech Stack** | PASS | React 19 + Vite (frontend), ASP.NET Core 10 (backend), Azure SQL + EF Core 10, Key Vault, App Insights, MSAL.js, Microsoft.Identity.Web. xUnit + NSubstitute + FluentAssertions (testing). |

**Post-design gate: PASS** — no violations. All design artifacts align with constitution principles.

## Generated Artifacts

| Artifact | Path | Description |
|----------|------|-------------|
| Research | [research.md](research.md) | 5 research topics: Entra External ID, MSAL.js v2 token storage, ASP.NET Core rate limiting, EF Core soft-delete, React autosave patterns |
| Data Model | [data-model.md](data-model.md) | User + Design entities with properties, indexes, validation rules, EF Core configuration, state transitions |
| API Contract | [contracts/designs-api.yaml](contracts/designs-api.yaml) | OpenAPI 3.0.3 — 8 endpoints: GET /api/me, GET/POST /api/designs, GET/PATCH/DELETE /api/designs/{id}, GET /api/designs/deleted, POST /api/designs/{id}/restore |
| Quickstart | [quickstart.md](quickstart.md) | Developer setup: Entra External ID configuration, frontend/backend setup, end-to-end verification |

## Next Step

Run `/speckit.tasks` to generate the task breakdown for implementation.
