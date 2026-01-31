# Cross Stitch Pattern Design Website – Software Design Document (SDD)

## 1. Document Control

- **Owner:** Engineering Lead (TBD)
- **Contributors:** Product (TBD), UX (TBD)
- **Status:** Draft
- **Version:** 0.1
- **Last Updated:** 2026-01-31

## 2. Purpose

This Software Design Document (SDD) translates product intent (PRD) and governing engineering principles (Project Constitution) into an implementation-oriented design for the Stitches application. It provides a shared understanding of architecture, component boundaries, key workflows, and non-functional requirements.

## 3. Scope

### In Scope (MVP)

- Full-stack design for:
  - **Frontend:** React SPA (Vite)
  - **Backend:** ASP.NET Core 10+ REST API
  - **Data:** Azure SQL Database
  - **Assets:** Azure Blob Storage
  - **Auth:** OAuth 2.0 / OIDC via delegated provider
- Key workflows: authentication, design CRUD, autosave, image upload + conversion (async), PDF/PNG export.
- Performance, security, and operational concerns required to meet MVP SLOs.

### Out of Scope (for this SDD)

- Pixel-perfect UI design specs, full UX wireframes.
- Detailed class-level design or code-level API contracts (will be captured in implementation specs / tickets).
- Collaboration features (sharing, comments/likes), premium tiers, AI enhancements.

## 4. Sources of Truth & Governance

- **Constitution authority:** In any conflict between documents, the constitution is the source of truth.
- **PRD intent:** The PRD defines user stories, acceptance criteria, and targets.
- **Note on current doc alignment:** The PRD’s “Backend (Node.js + Express)” section is treated as historical; the constitution mandates **ASP.NET Core 10+** for the backend.

## 5. Design Goals & Constraints

### 5.1 Goals

- **Cloud-first persistence:** Designs and assets persist to the cloud as the system of record.
- **Usability-first editing:** Keep the editor responsive while processing-intensive work runs asynchronously.
- **Security and privacy by default:** Strong ownership enforcement and secret management.
- **Operational readiness:** Instrumentation and performance targets baked into the design.

### 5.2 Key Constraints (MVP)

- OAuth-only login (no password storage).
- Default upload limit: 10 MB.
- Autosave every 30 seconds with **< 2 seconds** completion (p95).
- SPA + REST API (no GraphQL for MVP).

## 6. High-Level Architecture

### 6.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        Client (Browser)                      │
│  React SPA (Vite)                                            │
│  - Pattern Editor (Canvas)                                   │
│  - Palette / Tools / Layers                                  │
│  - Auth Callback Handling                                    │
│  - Autosave + Local Queue (unsynced edits)                   │
└───────────────────────────────┬──────────────────────────────┘
                                │ HTTPS
                                ▼
┌──────────────────────────────────────────────────────────────┐
│                      API (ASP.NET Core)                      │
│  - JWT validation + authorization                             │
│  - Designs CRUD + autosave endpoint                           │
│  - Upload initiation + job orchestration                      │
│  - Export endpoints                                           │
│  - Observability (logs/metrics/traces)                        │
└───────────────┬───────────────────────────┬──────────────────┘
                │                           │
                ▼                           ▼
┌──────────────────────────┐     ┌─────────────────────────────┐
│ Azure SQL Database        │     │ Azure Blob Storage          │
│ - Users                   │     │ - Uploaded images           │
│ - Designs (grid JSON)     │     │ - Export artifacts (optional)
└──────────────────────────┘     └─────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────────┐
│              Async Processing (Azure Functions/Worker)        │
│  - Photo -> palette mapping + grid generation                 │
│  - PDF/PNG generation for large exports                       │
│  - Retries + failure tracking                                 │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 Primary Data Flows

- **User edits design:** SPA updates UI immediately, schedules autosave.
- **Autosave:** SPA sends compact patch/full snapshot to API; API persists to SQL.
- **Photo conversion:** SPA uploads image; API stores blob, enqueues job; SPA polls job status.
- **Export:** SPA requests export; API generates synchronously for small jobs, or offloads to async for large jobs.

## 7. Frontend Design (React SPA)

### 7.1 Key Modules

- **Editor Shell**
  - Layout: canvas + tool panel + palette + layers/legend.
  - Navigation: design list, design editor, auth callback.

- **Canvas Rendering Layer**
  - Renders grid and stitches.
  - Supports zoom levels and panning.
  - Optimizes for 100×100 baseline at 60 FPS.

- **Design State**
  - Represents: grid (stitches), palette, symbols, text layers (pre-rasterization), metadata.
  - Supports undo/redo (target ≥ 50 actions per PRD).

- **Autosave + Sync Queue**
  - Triggers every 30 seconds.
  - Maintains “dirty” state and pending network requests.
  - If the API is unavailable, edits remain in-memory (and optionally persisted locally) and retry until sync succeeds.

### 7.2 State Management Strategy

- Use a single “design document” state container (Redux or Context + reducer) with:
  - Immutable updates for undo/redo.
  - Derived selectors for visible viewport.
  - Throttled rendering updates for large brush strokes.

### 7.3 Authentication UX Flow

1. User selects “Sign in”.
2. Browser redirects to OAuth provider.
3. Provider redirects back to SPA callback route.
4. SPA completes OAuth Authorization Code + PKCE, obtains an access token, and sends it to the API using `Authorization: Bearer <token>`.
5. SPA calls API endpoints; API validates authentication and ownership.

### 7.4 Key Frontend APIs (Conceptual)

- `GET /api/designs` list designs
- `POST /api/designs` create
- `GET /api/designs/{id}` fetch
- `PATCH /api/designs/{id}` update (autosave)
- `DELETE /api/designs/{id}` delete
- `POST /api/uploads` create upload + conversion job
- `GET /api/jobs/{jobId}` job status
- `POST /api/exports/pdf` export PDF
- `POST /api/exports/png` export PNG

## 8. Backend Design (ASP.NET Core)

### 8.1 Layering

- **API Layer (Controllers / Minimal APIs)**
  - Request validation, auth, rate limits.
- **Application Layer**
  - Use cases: CreateDesign, UpdateDesign, ConvertPhoto, ExportPattern.
- **Domain Layer**
  - Entities/value objects: Design, Palette, SymbolMap.
- **Infrastructure Layer**
  - SQL repository (EF Core recommended).
  - Blob storage client.
  - Queue/job client.

### 8.2 Authentication & Authorization

- Validate JWTs (or server sessions) issued by the configured OAuth/OIDC provider.
- Enforce ownership on every design read/write:
  - `design.userId` must match authenticated principal.
- Keep user profile minimal (provider id + display name/email as needed).

### 8.3 Data Access

- Azure SQL Database for users and designs.
- Use indexing on `Designs.userId`, `updatedAt` to support listing and sorting.
- Designs store grid data as JSON (schema versioned).

### 8.4 Image Upload & Conversion (Async)

**Goal:** keep the editor responsive and avoid long-running requests.

Proposed workflow:

1. API receives upload request metadata, returns a pre-signed upload (or accepts multipart upload).
2. Image stored in Blob Storage.
3. API enqueues conversion job with blob URI + conversion settings.
4. Worker converts image → palette-mapped grid and persists as a new/updated design.
5. SPA polls `GET /api/jobs/{jobId}` until completion.

Failure handling:

- Job retries with backoff.
- Job failure provides a user-friendly message and ability to retry.

### 8.5 Export (PDF/PNG)

- For small patterns: API can generate synchronously and stream file.
- For large patterns: enqueue export job and provide download link when ready.
- PDF must include grid + legend + stitch counts.

## 9. Data Model (High-Level)

### 9.1 SQL Tables

- `Users`
  - `id` (GUID)
  - `provider` (string)
  - `providerId` (string)
  - `email` (string, nullable)
  - `displayName` (string, nullable)
  - `createdAt`

- `Designs`
  - `id` (GUID)
  - `userId` (GUID, FK)
  - `title` (string)
  - `width` (int)
  - `height` (int)
  - `stitchData` (JSON)
  - `palette` (JSON)
  - `symbolMap` (JSON)
  - `uploadedImageUrl` (string, nullable)
  - `createdAt`, `updatedAt`
  - `isDeleted` (bool)

### 9.2 Blob Storage Layout

- Uploaded photos: `{userId}/{designId}/original.{ext}`
- Optional export cache: `{userId}/{designId}/exports/{timestamp}.{pdf|png}`

## 10. Non-Functional Requirements (Design Translation)

### 10.1 Performance Targets (SLOs)

- API latency: < 200 ms (p95) excluding image processing.
- Canvas rendering: 60 FPS at 100×100 grid baseline.
- Autosave: < 2 seconds (p95).
- Photo conversion: < 10 seconds (p95).
- Export: < 5 seconds (p95).
- Page load: < 2 seconds (p95).

### 10.2 Reliability & Availability

- MVP runs in a single Azure region.
- Use at least two App Service instances in production to support HA.
- Database backups enabled; restore procedure documented.

### 10.3 Security

- HTTPS everywhere.
- Secrets in Azure Key Vault; injected at runtime.
- No secrets in code, logs, or repo.
- Strict authorization checks on every design operation.

### 10.4 Privacy & Retention

- Designs and uploaded images retained indefinitely unless user deletes them (MVP).
- Account deletion workflow deferred to v1.1 (per constitution).

## 11. Observability

- Use **Azure Application Insights** and Azure Monitor for:
  - Request traces (API)
  - Dependency calls (SQL/Blob/Queue)
  - Frontend performance telemetry (core web vitals)
- Alerts:
  - Availability below 99.5% monthly
  - API latency > 500 ms (p95)
  - Error rate > 1%

## 12. Deployment & Environments

### 12.1 Environments

- **Dev:** single instance, minimal scaling
- **Staging:** mirrors production settings, used for beta and load testing
- **Prod:** multi-instance App Service, production-grade monitoring

### 12.2 Infrastructure as Code

- Bicep or Terraform to provision:
  - App Service + plan
  - Azure SQL
  - Blob Storage
  - Key Vault
  - Application Insights

## 13. Key Trade-offs & Rationale

- **ASP.NET Core vs Node/Express:** constitution mandates ASP.NET Core 10+; provides strong typing, performance, and ecosystem fit.
- **Cloud-first vs offline-first:** cloud is source of truth; offline mode limited to UI responsiveness and queued sync.
- **REST vs GraphQL:** REST for MVP simplicity and operability.

## 14. MVP Decisions

### 14.1 Authentication & Identity

- **Identity platform:** Microsoft Entra External ID (CIAM) configured with social identity providers.
- **API authentication:** Bearer JWT access tokens.
- **SPA flow:** OAuth Authorization Code + PKCE.
- **Token handling:** Access token held in-memory in the SPA; never stored in `localStorage`.

### 14.2 Design Grid Serialization

- **Persistence format:** Versioned JSON stored in `Designs.stitchData`.
- **Schema versioning:** Root-level `schemaVersion` field; increment on breaking schema changes.
- **Primary representation (MVP):**
  - `width`, `height` integers
  - `cells`: flat array of length `width * height`
  - each cell encodes:
    - palette color index
    - stitch type (full/half/quarter/backstitch)
    - optional orientation/metadata for fractional stitches
- **Autosave payload:** Full snapshot each autosave (optimize to patch/delta later if required).

### 14.3 Background Jobs

- **Queue:** Azure Storage Queues.
- **Retries:** Exponential backoff with a poison-queue pattern for repeated failures.
- **Status:** Job status and error details persisted to support polling (`Queued | Running | Succeeded | Failed`).

### 14.4 Export (PDF/PNG)

- **Approach:** Server-side generation for consistent fidelity.
- **Execution model:**
  - Small exports generated synchronously and streamed.
  - Large exports run as async jobs with polling + download.

## 15. Follow-ups

- Select specific PDF/PNG generation libraries after confirming licensing constraints.
