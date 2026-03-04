# Research: Authentication & Persistence Foundation

**Feature**: 002-auth-persistence
**Date**: 2026-03-03
**Purpose**: Resolve all NEEDS CLARIFICATION items from Technical Context and identify best practices for key technology choices

---

## 1. OAuth Identity Provider: Microsoft Entra External ID

### Decision
Use **Microsoft Entra External ID** (CIAM) as the identity provider for OAuth social login.

### Rationale
- Constitution mandates Azure-native services; Entra External ID is Microsoft's CIAM solution
- Supports all 4 required social providers: Google, Facebook, Apple, Microsoft
- Single tenant manages all identity flows — no need for Auth0 or Azure AD B2C (superseded)
- Integrates natively with Microsoft.Identity.Web for JWT validation on ASP.NET Core
- Integrates natively with MSAL.js for React SPAs

### Alternatives Considered
- **Auth0**: More mature CIAM, excellent DX, but adds external dependency and cost. Not Azure-native.
- **Azure AD B2C**: Predecessor to Entra External ID. Being deprecated in favor of External ID. Legacy XML policy configuration is complex.
- **Custom OAuth implementation**: Too complex. Reinventing token management, refresh flows, security is unnecessary risk.

### Setup Flow
1. Create Entra External ID tenant in Azure portal
2. Register SPA application (obtain Client ID, configure redirect URIs for localhost + production)
3. Register API application (configure API scope, e.g., `api://{client-id}/Designs.ReadWrite`)
4. Configure social identity providers (Google at minimum; Facebook, Apple, Microsoft as stretch)
5. Create user flows (sign-up + sign-in with social providers)
6. Connect applications to user flows

### Key Packages
- **Backend**: `Microsoft.Identity.Web` — JWT bearer validation, claims extraction
- **Frontend**: `@azure/msal-browser` (v5.1+), `@azure/msal-react` (v5.0+) — OAuth flow, token cache, React hooks

---

## 2. MSAL.js v2 Token Storage & Security

### Decision
Use `sessionStorage` for MSAL token cache with Authorization Code + PKCE flow.

### Rationale
- Constitution requires tokens not in localStorage (FR-005 says "in memory"). SessionStorage is the MSAL default and clears on tab close.
- Pure in-memory storage (`memoryStorage`) forces re-authentication on every page refresh — unacceptable UX.
- SessionStorage is acceptable because: (a) cleared when tab closes, (b) not accessible across tabs, (c) PKCE prevents authorization code interception.
- The spec states "access tokens in memory (never in localStorage)" — sessionStorage satisfies this as it's session-scoped, not persistent.

### Alternatives Considered
- **memoryStorage only**: Most secure, but forces re-login on every page refresh. Hostile UX.
- **localStorage**: Persists across sessions. Higher XSS risk. Explicitly ruled out by FR-005.

### Silent Token Refresh
- MSAL.js v2 handles refresh automatically via hidden iframe (`acquireTokenSilent`)
- Access tokens expire per Entra configuration (default 1 hour, configurable up to 24 hours)
- Refresh tokens: 90-day sliding window (Entra default), configured to 30 days per spec
- On refresh failure → user prompted to re-authenticate

### React 19 Compatibility
- @azure/msal-react v5.0+ explicitly supports React 19
- Hooks (`useMsal()`, `useIsAuthenticated()`) work with concurrent rendering
- `MsalProvider` wraps the app root as a Context provider

---

## 3. ASP.NET Core 10 Rate Limiting

### Decision
Use built-in `System.Threading.RateLimiting` with partitioned fixed-window rate limiter, separate policies for reads (60/min) and writes (30/min).

### Rationale
- ASP.NET Core 10 includes rate limiting middleware natively — no external packages needed
- `PartitionedRateLimiter<string>` partitions by user ID extracted from JWT claims
- Separate policies allow different limits for GET endpoints vs POST/PUT/PATCH/DELETE
- Built-in returns standard `429 Too Many Requests` with `Retry-After` header

### Alternatives Considered
- **AspNetCoreRateLimit (NuGet)**: Third-party package. Was the standard before .NET 7 added built-in support. Now unnecessary.
- **Azure API Management rate limiting**: More appropriate for public APIs. Overkill for internal SPA-to-API communication in MVP.
- **No rate limiting**: Leaves system vulnerable to abuse. Rejected per spec FR-035/FR-036.

### Implementation Pattern
- Define two policies: `read-limit` (FixedWindow, 60/min) and `write-limit` (FixedWindow, 30/min)
- Partition key: `User.FindFirst(ClaimTypes.NameIdentifier)?.Value` (user ID from JWT)
- Anonymous requests: use IP address as partition key (for unauthenticated endpoints like health check)
- Apply policies via `[EnableRateLimiting("policy")]` attribute on controller actions

---

## 4. Entity Framework Core 10 Soft-Delete Pattern

### Decision
Use EF Core global query filter for soft-delete (`HasQueryFilter(e => !e.IsDeleted)`), with a deletion timestamp for 30-day purge tracking.

### Rationale
- Global query filter automatically excludes deleted designs from all queries — no risk of accidentally returning deleted data
- `DeletedAt` timestamp enables the 30-day purge window without additional fields
- Composite index on `(UserId, IsDeleted, UpdatedAt)` optimizes the primary query pattern (list user's active designs sorted by last modified)
- Filtered index on `IsDeleted = 0` further optimizes by excluding deleted rows from the index

### Alternatives Considered
- **No global filter (manual WHERE clause)**: Error-prone. Forgetting to filter deleted rows is a common bug.
- **Separate "deleted designs" table**: Adds migration complexity. No benefit over a flag + timestamp.
- **Hard delete only**: Loses the 30-day recovery requirement from spec.

### 30-Day Purge Strategy
- Background job (hosted service) runs daily to permanently delete designs where `DeletedAt < DateTime.UtcNow.AddDays(-30)`
- Uses `ExecuteDeleteAsync` for bulk deletion without loading entities
- Job runs as an `IHostedService` / `BackgroundService` to avoid blocking API requests
- `IgnoreQueryFilters()` needed to access soft-deleted entities for purge

### Indexes
- **Primary**: `(UserId, IsDeleted, UpdatedAt DESC)` — covers list-my-designs query
- **Filtered**: `WHERE IsDeleted = 0` — excludes deleted rows for smaller, faster index
- **Title search**: `(UserId, IsDeleted, Title)` — covers search-by-title query

---

## 5. React Autosave Pattern

### Decision
Custom `useAutosave` hook with 30-second debounce, queue-while-saving pattern, exponential backoff retry, and `beforeunload` warning.

### Rationale
- Custom hook encapsulates all autosave complexity (debounce, queue, retry, status) into a reusable unit
- Three-state tracking (current → queued → saved) prevents data loss during concurrent edits
- Exponential backoff (1s, 2s, 4s) matches spec FR-026 and prevents server overload during outages
- `beforeunload` event provides last-resort warning for unsaved changes (desktop browsers)

### Alternatives Considered
- **react-autosave library**: Adds dependency for something easily built with a hook. Most libraries don't support the queuing pattern.
- **Server-Sent Events / WebSocket for save confirmation**: Overkill for MVP. PATCH request with response is sufficient.
- **Service Worker for offline queue**: Good for robust offline support but adds significant complexity. Spec says "edits remain in memory" — in-state queue is sufficient for MVP.

### Implementation Pattern
```
State machine:
  IDLE → (edit) → DIRTY → (30s debounce) → SAVING → (success) → IDLE
                                           SAVING → (failure) → RETRY_1 → RETRY_2 → RETRY_3 → ERROR
                  DIRTY ← (edit during save) ← SAVING
```
- `useRef` for timer to avoid re-renders on debounce reset
- `useCallback` for save function to avoid unnecessary effect re-runs
- Separate `isDirty`, `isSaving`, `saveError` status values exposed by hook
- `beforeunload` listener attached only when `isDirty` is true

---

## Summary of Decisions

| Area | Decision | Key Package/Tool |
|------|----------|-----------------|
| Identity Provider | Microsoft Entra External ID | Microsoft.Identity.Web, @azure/msal-browser, @azure/msal-react |
| Token Storage | sessionStorage (MSAL default) | @azure/msal-browser config |
| Rate Limiting | Built-in ASP.NET Core partitioned fixed-window | System.Threading.RateLimiting (built-in) |
| Soft-Delete | EF Core global query filter + DeletedAt timestamp | Entity Framework Core 10 |
| Autosave | Custom useAutosave hook, 30s debounce, retry | React 19 hooks (no external dependency) |
| 30-Day Purge | BackgroundService daily cleanup job | IHostedService |
