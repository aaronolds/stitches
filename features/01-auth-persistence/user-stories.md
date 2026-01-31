# Feature 1: Authentication & Persistence Foundation

**Priority:** P1 (Foundation)  
**Status:** Not Started  
**Dependencies:** Feature 0 (Infrastructure)  
**Blocks:** Features 2, 3, 4

## Overview

This feature establishes user identity management and cloud-based design persistence. It enables users to authenticate via OAuth social providers and ensures all designs are saved to Azure SQL Database with automatic backup and recovery capabilities.

**Rationale:**
Authentication and persistence form the foundation of the cloud-first architecture mandated by the Constitution. No other features can function without the ability to identify users and persist their design data. These two stories are tightly coupled—autosave requires authenticated storage.

**What this enables:**
- Users can create accounts and log in (OAuth only, no passwords)
- Designs are owned by users and persisted to the cloud
- Multi-device access to the same design library
- Automatic save every 30 seconds prevents data loss
- Draft recovery after browser crashes or network interruptions

---

## User Story 1.1: User Authentication & Design Storage

**(PRD Story #5)**

**As** a returning user, **I want to** log in with my Google/Facebook/Apple/Microsoft account and access my saved designs, **so that** I can manage my portfolio and work across devices.

### Priority
**P1** - Foundation for all user data

### User Personas
- **Emma** (Amateur Hobbyist): Wants to save holiday photo patterns and access them from iPad and laptop
- **Maya** (Small Business Owner): Needs cloud storage for 10-20 designs/month; file management is currently chaotic
- **Alex** (Casual Experimenter): Expects modern web apps to "just work" with Google login

### Why This Priority
Without authentication, users lose their work when they close the browser. Cloud storage is the #1 feature differentiator from desktop tools per BRD. This enables the Constitution's Cloud-First Architecture principle.

### Independent Test
User can visit the application, click "Sign in with Google", complete OAuth flow, create a blank design, log out, log back in, and see the saved design in their library.

---

### Acceptance Criteria (from PRD)

#### 1. OAuth Login Flow

**Given** an unauthenticated user visits the application  
**When** they click "Sign in"  
**Then** they see OAuth provider options: Google, Facebook, Apple ID, Microsoft accounts

**Given** user selects an OAuth provider  
**When** they complete the provider's authentication flow  
**Then** they are redirected back to the application with a valid access token

**Given** user completes OAuth for the first time  
**When** they return to the application  
**Then** a user account is created with minimal profile data (email, display name)

#### 2. Session Management

**Given** a user successfully logs in  
**When** they interact with the application  
**Then** the SPA holds the access token in memory (never in `localStorage`)

**Given** a user's access token expires (24 hours per SDD)  
**When** they make an API request  
**Then** the refresh token is used to obtain a new access token automatically

**Given** a user's refresh token expires (30 days per SDD)  
**When** they make an API request  
**Then** they are prompted to log in again

#### 3. Design CRUD Operations

**Given** an authenticated user  
**When** they create a new design  
**Then** `POST /api/designs` creates a design record with `userId` ownership

**Given** an authenticated user  
**When** they view their design library  
**Then** `GET /api/designs` returns only designs where `userId` matches (paginated, default 20/page)

**Given** an authenticated user  
**When** they open a specific design  
**Then** `GET /api/designs/{id}` returns the design data only if they own it (authorization check)

**Given** an authenticated user  
**When** they update a design  
**Then** `PATCH /api/designs/{id}` updates the design only if they own it

**Given** an authenticated user  
**When** they delete a design  
**Then** `DELETE /api/designs/{id}` soft-deletes the design (`isDeleted = true`) only if they own it

#### 4. Design Metadata

**Given** a design is created  
**When** it is stored in the database  
**Then** the following metadata is captured:
- `id` (GUID)
- `userId` (GUID, foreign key)
- `title` (string, default "Untitled Design")
- `width` (int, stitch count)
- `height` (int, stitch count)
- `stitchData` (JSON, see SDD Section 14.2)
- `palette` (JSON)
- `symbolMap` (JSON)
- `uploadedImageUrl` (string, nullable, Blob Storage reference)
- `createdAt` (timestamp)
- `updatedAt` (timestamp)
- `isDeleted` (bool, default false)

#### 5. Design Listing Features

**Given** an authenticated user views their design library  
**When** they interact with the list  
**Then** they can:
- Search by design title
- Sort by name, creation date, or last modified date
- Filter by colour count (number of DMC colours used)
- See a thumbnail preview for each design

#### 6. Authorization Enforcement

**Given** an authenticated user  
**When** they attempt to access another user's design  
**Then** the API returns `403 Forbidden` and logs the unauthorized access attempt

**Given** an unauthenticated user  
**When** they attempt any design operation  
**Then** the API returns `401 Unauthorized` and prompts for login

---

## User Story 1.2: Autosave & Draft Recovery

**(PRD Story #4)**

**As** a designer, **I want** my changes to autosave every 30 seconds, **so that** I don't lose work if my browser crashes.

### Priority
**P1** - Critical data protection feature

### User Personas
- **Emma** (Amateur Hobbyist): Worries about losing work; not tech-savvy enough to remember to save manually
- **Maya** (Small Business Owner): Can't afford to lose 30 minutes of editing due to browser crash
- **Alex** (Casual Experimenter): Expects modern web apps to autosave (like Google Docs)

### Why This Priority
Data loss is unacceptable per Constitution Principle I (Cloud-First Architecture). Autosave directly addresses the BRD's goal of "increase user retention through reliable autosave." Without autosave, users risk losing significant work, which destroys trust.

### Independent Test
User opens a design, makes 5 stitch edits, waits 30 seconds (sees autosave indicator), kills the browser tab, reopens the application, and sees all 5 edits preserved.

---

### Acceptance Criteria (from PRD)

#### 1. Automatic Save Trigger

**Given** a user is editing a design  
**When** 30 seconds elapse since the last edit  
**Then** the SPA sends an autosave request to `PATCH /api/designs/{id}`

**Given** a user makes rapid edits (< 30 seconds apart)  
**When** the autosave timer is running  
**Then** the timer resets with each new edit (debounced)

**Given** an autosave request is in progress  
**When** the user makes additional edits  
**Then** those edits queue for the next autosave cycle (no concurrent autosaves)

#### 2. Autosave Performance

**Given** an autosave request is triggered  
**When** the API persists the design data  
**Then** the operation completes in < 2 seconds (p95) per Constitution SLO

**Given** an autosave request fails (network error, server error)  
**When** the failure is detected  
**Then** the SPA retries up to 3 times with exponential backoff (1s, 2s, 4s)

#### 3. Autosave UI Indicator

**Given** an autosave operation is triggered  
**When** the request is in progress  
**Then** the UI displays a "Saving..." indicator

**Given** an autosave operation completes successfully  
**When** the response is received  
**Then** the UI displays "All changes saved" with a checkmark icon (visible for 2 seconds)

**Given** an autosave operation fails after retries  
**When** the final retry fails  
**Then** the UI displays "Changes not saved - retry?" with an alert icon

**Given** the user has unsaved changes (dirty state)  
**When** they attempt to close the browser tab  
**Then** the browser shows "You have unsaved changes" confirmation dialog

#### 4. Draft Recovery After Crash

**Given** a user is editing a design  
**When** their browser crashes or tab is force-closed  
**Then** the last autosaved version is retained in the database

**Given** a user's browser crashed with unsaved edits  
**When** they reopen the application and navigate to the design  
**Then** the design loads with the last successfully autosaved state

**Given** a user's network connection drops  
**When** autosave fails repeatedly  
**Then** pending edits remain in the SPA's memory and retry when connection is restored

#### 5. Autosave Retention

**Given** a design is autosaved  
**When** no further edits are made  
**Then** the autosaved draft is retained for ≥ 7 days per PRD

**Given** a draft is ≥ 7 days old with no activity  
**When** the retention policy runs  
**Then** the draft remains (retention is indefinite per Constitution until user deletes)

#### 6. Manual Save Checkpoint

**Given** a user clicks the "Save" button explicitly  
**When** the save operation completes  
**Then** a manual checkpoint is created (future: for version history in v1.1)

**Given** a user has no unsaved changes  
**When** they view the design title area  
**Then** the last modification timestamp is displayed (e.g., "Last saved: 2 minutes ago")

---

## Edge Cases & Considerations

### Authentication
- **OAuth provider downtime:** Show user-friendly error, suggest trying another provider
- **Concurrent sessions:** Same user logs in from two devices, edits the same design (future: conflict resolution in v1.1; MVP uses last-write-wins)
- **Token refresh failure:** Log user out gracefully with "Session expired" message
- **Email missing from OAuth profile:** Fallback to providerId + displayName only

### Design Storage
- **Large designs:** What if `stitchData` JSON exceeds SQL text field limit? (Test up to 500×500 grids)
- **Database connection loss during save:** Retry with exponential backoff; show error to user after 3 failures
- **User creates thousands of designs:** Pagination ensures listing performance; future: archive old designs
- **Malicious design deletion attempts:** Authorization checks on every DELETE; audit log in v1.1

### Autosave
- **Rapid editing (< 30s cycles):** Debounce timer ensures only 1 save per 30s minimum; no save storms
- **Offline editing:** Edits stay in memory; queue syncs when connection returns (Constitution allows offline UI, but cloud is source of truth)
- **Autosave during image processing:** Story 3's async jobs won't block autosave; autosave only affects `stitchData` JSON
- **Browser crashes during autosave:** AWS SQL transaction rollback ensures data integrity; last successful autosave is retained

---

## Success Criteria

### Feature 1 Complete When:
- ✅ User can log in with Google (minimum; all 4 providers bonus)
- ✅ User can create, view, edit, delete designs (CRUD operational)
- ✅ Each design is tied to `userId`; authorization checks pass
- ✅ Autosave triggers every 30 seconds; UI indicator updates correctly
- ✅ Autosave completes in < 2 seconds (p95) per Constitution SLO
- ✅ Browser crash recovery: last autosaved version restored on reload
- ✅ No secrets in code; OAuth client secrets stored in Azure Key Vault
- ✅ Integration tests pass for login flow and design CRUD

### Performance Targets
- **API latency:** `GET /api/designs` < 200 ms (p95) per Constitution
- **Autosave latency:** `PATCH /api/designs/{id}` < 2 seconds (p95) per Constitution
- **Design listing:** Pagination supports ≥ 1000 designs per user without degradation

---

## Technical References

### Constitution Alignment
- **Principle I: Cloud-First Architecture** - All designs cloud-persisted from creation
- **Principle IV: Security & Privacy-First** - OAuth-only auth, no passwords; authorization on every CRUD
- **Principle V: Performance-First Design** - Autosave < 2s (p95)

### SDD Alignment
- **Section 7.3:** Authentication UX Flow (OAuth Authorization Code + PKCE)
- **Section 8.2:** Authentication & Authorization (JWT validation, ownership enforcement)
- **Section 8.3:** Data Access (SQL schema, indexing on userId/updatedAt)
- **Section 9.1:** SQL Tables (Users, Designs schema)
- **Section 14.1:** MVP Decision - Microsoft Entra External ID (CIAM) with social providers

### PRD Alignment
- **Story #5:** User Authentication & Design Storage (acceptance criteria preserved above)
- **Story #4:** Autosave & Draft Recovery (acceptance criteria preserved above)
- **Success Criteria:** First-Session Success 70%, Retention 40%, Autosave < 2s (p95)

---

## Dependencies & Blockers

**Depends On:**
- Feature 0: Infrastructure (Azure SQL Database provisioned, OAuth provider configured in Key Vault)

**Blocks:**
- Feature 2: Core Editor (requires design CRUD to persist canvas edits)
- Feature 3: Content Generation (requires design ownership to attach uploaded images)
- Feature 4: Export (requires design data to export)

**External Dependencies:**
- Microsoft Entra External ID (or Auth0/Azure AD B2C) configured with social identity providers
- Azure SQL Database read/write permissions
- Azure Key Vault access for OAuth client secrets

---

## Follow-up Work (Post-Feature 1)

After Feature 1 completes, the following becomes possible:
- **Feature 2** can implement autosave for canvas edits (design CRUD already operational)
- **Feature 3** can attach uploaded images to user-owned designs
- **Feature 4** can generate exports for authenticated users' designs

**Future Enhancements (v1.1+):**
- Version history for designs (rollback to previous autosaves)
- Conflict resolution for concurrent editing across devices
- Account deletion workflow (GDPR compliance)
- Design sharing with public links (read-only access without auth)

---

**Status:** Not Started  
**Estimated Effort:** 2-3 weeks (OAuth setup + database schema + autosave logic)  
**Owners:** Backend team (auth/API) + Frontend team (OAuth flow + autosave UI)
