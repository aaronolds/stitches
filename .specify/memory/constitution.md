# Stitches Project Constitution

<!-- 
  Sync Impact Report (Constitution v1.1.1)
  
  Ratification: 2026-01-31 (Initial Constitution from BRD/PRD)
  Last Amended: 2026-01-31 (Backend testing tool: Moq → NSubstitute)
  
  Amendment Summary:
  - Backend mocking tool updated: Moq → NSubstitute
  - Version bumped: 1.1.0 → 1.1.1 (PATCH: tooling refinement, no principle changes)
  - Rationale: NSubstitute flexibility & API design; lighter dependency surface
  
  Template Audit Status:
  - .specify/templates/plan-template.md: ✅ Aligned
  - .specify/templates/spec-template.md: ✅ Aligned
  - .specify/templates/tasks-template.md: ✅ Aligned
  
-->

## Core Principles

### I. Cloud-First Architecture

Every design, asset, and user data is cloud-persisted from creation. No local-only fallback; offline mode is limited to UI responsiveness while changes queue for sync. Cloud storage is the source of truth. Azure App Service, Azure SQL Database, and Azure Blob Storage are mandatory for all data paths. Autosave must trigger every 30 seconds with < 2 second completion (p95). If cloud storage fails, the user sees a clear error; edits are NOT lost locally but remain unsync'd until connection is restored.

**Why**: Users work across devices; loss of work is unacceptable. Stateless server design enables horizontal scaling and reduces ops complexity.

---

### II. Accessibility & Simplicity

The design canvas is web-first (React SPA) and accessible to hobbyists with basic computer skills. Every interaction must have a low cognitive load; no feature is added without a clear use case tied to a user persona (Emma, Maya, or Alex). Free tier on MVP; monetization deferred. OAuth-only login (no password management). HTML/CSS/JavaScript standards ensure browser compatibility (modern browsers on desktop and mobile PWA). Documentation must be plain English, not jargon.

**Why**: Professional desktop tools gatekeep creativity; accessible tools expand adoption and retention.

---

### III. User-Centric Quality

Photo-to-pattern conversion must achieve ≥ 4/5 user satisfaction before launch. All features validated with beta users; feedback shapes priorities. A/B testing on export formats, UI layout, and palette defaults is expected. Success threshold: 70% of new users complete a first design in their first session. If any accepted acceptance criterion fails after deploy, incident severity determined; root cause documented; no blame culture.

**Why**: Feature completeness is meaningless if users don't find value. Retention above feature count.

---

### IV. Security & Privacy-First

User email and profile name only; no password storage (OAuth delegated). Designs are owned by user ID; authorization checks on every design CRUD operation. Secrets (DB connection string, storage key, OAuth client secret) stored in Azure Key Vault; environment variables injected at runtime, never committed. HTTPS mandatory. GDPR/CCPA deletion supported in v1.1. No third-party data sharing without explicit user consent and Privacy Policy transparency.

**Why**: Hobbyists and small business owners trust with their creative work; breach destroys reputation and legal standing.

---

### V. Performance-First Design

API latency target: < 200 ms (p95) excluding image processing. Canvas render: 60 FPS at 100×100 grid. Autosave: < 2 seconds (p95). Export (PDF/PNG): < 5 seconds (p95). Photo conversion: < 10 seconds (p95). If performance regression detected (via monitoring or user report), investigation initiated within 24 hours. Image processing runs asynchronously; UI remains responsive. Page load time: < 2 seconds (p95) with React bundle cached and CDN'd.

**Why**: Editing friction compounds; slow export kills sharing workflows. Performance is a feature for hobbyists on varied devices.

---

## Architecture & Technology Stack

### Mandatory Tech Choices

- **Frontend**: React (Vite build, Context API or Redux for state)
- **Backend**: ASP.NET Core 10+ (C#, REST API, no GraphQL for MVP)
- **Database**: Azure SQL Database (zone-redundant backup in prod)
- **Storage**: Azure Blob Storage (RA-GRS for geo-replication)
- **Auth**: OAuth 2.0 (Google, Facebook, Apple, Microsoft; delegated provider)
- **Secrets**: Azure Key Vault (environment runtime injection)
- **Compute**: Azure App Service (2+ instances in prod for HA)
- **CDN**: Azure CDN (caches React bundle, fonts, static exports)
- **Testing**: Vitest (frontend), xUnit + NSubstitute (backend)
- **Deployment**: Infrastructure as Code (Bicep or Terraform); CI/CD pipeline required

### Single Region (MVP Only)

MVP deploys to single Azure region (East US). Multi-region failover deferred to v1.1. Failover procedure documented but not automated in MVP.

### Versioning

Follows semantic versioning: MAJOR.MINOR.PATCH

- **MAJOR**: Breaking API changes, principle removals, authentication model change
- **MINOR**: New feature, new user story acceptance, new template sections
- **PATCH**: Bug fixes, performance improvements, clarifications, UI refinements, typo fixes

---

## Security & Data Governance

### Secrets Management

- All secrets (DB connection, blob key, OAuth client secret, JWT signing key) stored in Azure Key Vault
- Environment config loads from Key Vault at runtime
- No secrets in `.env` files, code, or logs
- Rotation procedure: TBD (v1.1, but documented as requirement)
- Audit logging on Key Vault access; monthly review

### API Authorization

- Every CRUD operation validates JWT token and checks `userId` field
- Users can only access/modify designs owned by their `userId`
- DELETE operations require explicit confirmation; soft deletes initially (isDeleted flag), hard purge in v1.1
- Session tokens expire after 24 hours; refresh tokens issued for 30 days

### Data Retention & Deletion

- Designs retained indefinitely until user deletes (MVP)
- Uploaded images retained for ≥ 90 days; lifecycle policy auto-deletes > 90 days
- User deletion (account removal) cascades to all designs and images (v1.1); MVP has no account deletion UI
- GDPR Data Subject Access Request procedure: TBD (v1.1)

---

## Performance Standards & Monitoring

### SLOs (Service Level Objectives)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Availability** | 99.5% monthly | Azure Application Insights monitoring; incident if degraded |
| **API latency (p95)** | < 200 ms | Excluding image processing; includes DB roundtrip |
| **Canvas FPS** | 60 FPS | At 100×100 grid; test on iPad Gen 5 minimum |
| **Autosave latency (p95)** | < 2 seconds | Debounced, optimistic UI update |
| **Photo conversion (p95)** | < 10 seconds | Async job; measured from upload to result |
| **Export latency (p95)** | < 5 seconds | PDF and PNG; measured end-to-end |
| **Page load time (p95)** | < 2 seconds | React bundle + initial render |

### Monitoring & Alerting

- Application Insights (Azure) for logs, traces, metrics
- Alerts triggered if API latency exceeds 500 ms (p95), availability drops below 99.5%, or error rate > 1%
- Weekly metrics review; escalation if SLOs miss 2 weeks in a row
- No heroic manual fixes; root cause analysis required

---

## Development Quality Gates

### Before Feature Merge

1. All acceptance criteria from spec.md verified by author + code review
2. Tests pass (unit, contract, integration) with > 80% code coverage
3. No secrets in code; Azure Key Vault checks pass
4. Performance baseline met: API < 500 ms (p95), canvas 60 FPS
5. No high/critical security warnings from static analysis
6. Documentation updated (README, API docs, user guide if applicable)

### Release Criteria (MVP to Production)

1. All acceptance criteria Stories 1–7 pass on staging
2. 50+ beta users report ≥ 4/5 satisfaction on photo conversion
3. Uptime ≥ 99% for 7 consecutive days on staging
4. Load test: 100 concurrent users, no degradation
5. OAuth flow tested; JWT validation verified
6. Database backup and restore procedure tested
7. Incident runbook drafted (common failure scenarios)

## Governance

### Constitution Authority

This Constitution is the source of truth for Stitches governance. It supersedes all product documents (BRD, PRD) in case of conflict. Questions on feature scope, tech choices, or trade-offs are resolved by re-reading the principles first.

### Amendment Procedure

1. Issue created describing proposed amendment + rationale
2. Author traces impact to affected principles, templates, and docs
3. Code review + product owner approval required
4. Sync Impact Report generated (version bump, files updated, follow-up TODOs)
5. Merge to main after approval; constitution.md and dependent files updated in single commit

### Version & Amendment History

| Version | Date | Change |
|---------|------|--------|
| 1.1.1 | 2026-01-31 | Backend testing: Moq → NSubstitute (tooling refinement) |
| 1.1.0 | 2026-01-31 | Backend tech: Node.js + Express → ASP.NET Core 10+ (C#) |
| 1.0.0 | 2026-01-31 | Initial constitution ratified from BRD + PRD |

### Compliance Validation

At each milestone (end of MVP, before v1.1 release):

1. Each principle re-stated in plain English; no drift from original intent
2. Feature backlog reviewed against principles; conflicts resolved
3. Architecture review: tech stack still optimal? Cost on track?
4. User retention data analyzed; if < 40% day-30 return, escalate to product owner
5. Performance SLOs reviewed; if consistently missed, investigation + mitigation plan required

---

**Version**: 1.1.1 | **Ratified**: 2026-01-31 | **Last Amended**: 2026-01-31
