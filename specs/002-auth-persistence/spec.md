# Feature Specification: Authentication & Persistence Foundation

**Feature Branch**: `002-auth-persistence`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Authentication & Persistence Foundation - User authentication via OAuth social providers and cloud-based design persistence with autosave"

## Clarifications

### Session 2026-03-03

- Q: If a user signs in with Google, then later signs in with Microsoft using the same email, how should the system handle this? → A: Separate accounts per provider (no cross-provider linking; simplest MVP)
- Q: What should an unauthenticated user see when they first visit the application? → A: Sign-in wall only — users must authenticate before seeing any application content
- Q: What validation constraints apply to design title and dimensions? → A: Title max 255 characters; dimensions between 1×1 and 1000×1000 stitches
- Q: Can users recover soft-deleted designs, and if so, for how long? → A: "Recently Deleted" view with 30-day recovery window, then permanent purge
- Q: Should design API operations be rate-limited per user? → A: Moderate limits — 60 req/min reads, 30 req/min writes per user

## User Scenarios & Testing *(mandatory)*

### User Story 1 - OAuth Login & Account Creation (Priority: P1)

As a new or returning user, I want to sign in with my existing social account (Google, Facebook, Apple, or Microsoft) so that I can access the application without creating yet another password, and have my identity established for saving designs.

**Why this priority**: Without authentication, no user data can be persisted or associated with an individual. This is the foundational gate for all other functionality in the application. The cloud-first architecture requires user identity to function.

**Independent Test**: A user visits the application, clicks "Sign in with Google", completes the OAuth consent flow, is redirected back to the application as an authenticated user, sees their display name, logs out, and then logs back in to confirm their account persists.

**Acceptance Scenarios**:

1. **Given** an unauthenticated user visits the application, **When** they click "Sign in", **Then** they see OAuth provider options for Google, Facebook, Apple, and Microsoft accounts.
2. **Given** an unauthenticated user visits the application, **When** the page loads, **Then** they see only the sign-in options and cannot access any application features until authenticated.
2. **Given** a user selects an OAuth provider, **When** they complete the provider's authentication flow, **Then** they are redirected back to the application as an authenticated user with a valid session.
3. **Given** a user completes OAuth for the first time, **When** they return to the application, **Then** a user account is created with their email and display name from the provider profile.
4. **Given** a user who previously created an account, **When** they sign in again with the same provider, **Then** they are signed into their existing account (no duplicate accounts).
5. **Given** a user is authenticated, **When** their session token expires after 24 hours, **Then** a new token is obtained automatically using a refresh mechanism without interrupting the user.
6. **Given** a user's refresh credential expires after 30 days, **When** they make a request, **Then** they are prompted to sign in again.
7. **Given** a user is authenticated, **When** they click "Sign out", **Then** their session is terminated and they return to the unauthenticated landing page.

---

### User Story 2 - Design CRUD & Library Management (Priority: P1)

As an authenticated user, I want to create, view, edit, and delete my cross-stitch designs so that I can manage my design portfolio in the cloud and access it from any device.

**Why this priority**: Design persistence is the core value proposition of the application. Without the ability to save and manage designs, the application cannot serve its primary purpose. This is co-equal with authentication as the foundational data layer.

**Independent Test**: An authenticated user creates a new blank design, gives it a title, views it in their design library, opens it, modifies its title, returns to the library to confirm the updated title, then deletes it and confirms it no longer appears in the library.

**Acceptance Scenarios**:

1. **Given** an authenticated user, **When** they create a new design, **Then** a design record is created with their user identity as the owner, a default title of "Untitled Design", and timestamps for creation and modification.
2. **Given** an authenticated user with saved designs, **When** they view their design library, **Then** they see a paginated list (default 20 per page) showing only designs they own.
3. **Given** an authenticated user, **When** they open a specific design they own, **Then** the full design data is returned including stitch data, palette, and metadata.
4. **Given** an authenticated user, **When** they update a design they own (title, stitch data, palette, etc.), **Then** the design is updated and the modification timestamp is refreshed.
5. **Given** an authenticated user, **When** they delete a design they own, **Then** the design is soft-deleted (marked as deleted with a deletion timestamp) and no longer appears in their active library.
6. **Given** an authenticated user, **When** they view "Recently Deleted", **Then** they see their soft-deleted designs that are less than 30 days old and can restore them.
7. **Given** an authenticated user, **When** they attempt to access a design owned by another user, **Then** they receive a "Forbidden" response and the unauthorized access attempt is logged.
7. **Given** an unauthenticated user, **When** they attempt any design operation, **Then** they receive an "Unauthorized" response and are prompted to sign in.

---

### User Story 3 - Design Search, Sort & Filter (Priority: P2)

As an authenticated user with many designs, I want to search, sort, and filter my design library so that I can quickly find the design I want to work on.

**Why this priority**: As users accumulate designs, finding the right one becomes important for usability. This enhances the core CRUD experience but is not strictly required for the basic create-save-load workflow.

**Independent Test**: An authenticated user with at least 5 designs can search by title to find a specific design, sort the library by most recently modified, and filter by colour count to narrow results.

**Acceptance Scenarios**:

1. **Given** an authenticated user views their design library, **When** they enter a search term, **Then** only designs with titles matching the search term are displayed.
2. **Given** an authenticated user views their design library, **When** they select a sort option, **Then** designs are reordered by name (alphabetical), creation date, or last modified date as chosen.
3. **Given** an authenticated user views their design library, **When** they filter by colour count, **Then** only designs with the specified number of colours in their palette are shown.
4. **Given** an authenticated user views their design library, **When** they view the list, **Then** each design displays a thumbnail preview alongside its title and metadata.

---

### User Story 4 - Autosave with Visual Feedback (Priority: P1)

As a designer editing a cross-stitch pattern, I want my changes to be automatically saved every 30 seconds so that I never lose work due to browser crashes, network issues, or forgetting to save manually.

**Why this priority**: Data loss is unacceptable and is the #1 threat to user trust and retention. Users expect modern web applications to autosave (similar to Google Docs). This directly supports the cloud-first architecture principle and the business goal of increasing retention through reliable autosave.

**Independent Test**: A user opens a design, makes 5 stitch edits, waits 30 seconds and sees a "Saving..." indicator followed by "All changes saved", then kills the browser tab, reopens the application, navigates to that design, and sees all 5 edits preserved.

**Acceptance Scenarios**:

1. **Given** a user is editing a design, **When** 30 seconds elapse since the last edit, **Then** the application sends an autosave request to persist the current design state.
2. **Given** a user makes rapid edits less than 30 seconds apart, **When** the autosave timer is running, **Then** the timer resets (debounces) with each new edit so that saves occur at most once per 30-second quiet period.
3. **Given** an autosave is in progress, **When** the user makes additional edits, **Then** those edits are queued for the next autosave cycle (no concurrent save requests).
4. **Given** an autosave request is triggered, **When** the save is in progress, **Then** the UI displays a "Saving..." indicator.
5. **Given** an autosave completes successfully, **When** the response is received, **Then** the UI displays "All changes saved" with a checkmark icon visible for 2 seconds.
6. **Given** an autosave request fails, **When** the failure is detected, **Then** the system retries up to 3 times with exponential backoff (1 second, 2 seconds, 4 seconds).
7. **Given** all autosave retries fail, **When** the final retry fails, **Then** the UI displays "Changes not saved - retry?" with an alert icon.
8. **Given** the user has unsaved changes (dirty state), **When** they attempt to close the browser tab, **Then** a browser confirmation dialog warns them about unsaved changes.

---

### User Story 5 - Draft Recovery After Crash (Priority: P1)

As a designer whose browser has crashed or whose network dropped during editing, I want to recover my last autosaved work so that I lose at most 30 seconds of edits.

**Why this priority**: Recovery is inextricable from autosave — without recovery, autosave has no value. Users must trust that the application protects their work even in failure scenarios. This is critical for user confidence and retention.

**Independent Test**: A user opens a design, makes edits, waits for autosave to complete (confirmed by "All changes saved"), force-closes the browser (simulating a crash), reopens the application, navigates to the design, and confirms all autosaved edits are intact.

**Acceptance Scenarios**:

1. **Given** a user's browser crashes or is force-closed, **When** the user reopens the application and navigates to the design, **Then** the design loads with the last successfully autosaved state.
2. **Given** a user's network connection drops, **When** autosave fails repeatedly, **Then** pending edits remain in the application's memory and automatically retry when the connection is restored.
3. **Given** a user's network is restored after an outage, **When** queued edits are sent, **Then** the design is updated to include all edits made during the offline period.

---

### User Story 6 - Manual Save Checkpoint (Priority: P3)

As a designer, I want to explicitly click "Save" to create a manual checkpoint of my design so that I can mark important milestones in my work.

**Why this priority**: This is a supplementary convenience feature. Autosave handles data protection, but manual save gives users a sense of control and lays groundwork for future version history. Non-critical for MVP.

**Independent Test**: A user opens a design, makes edits, clicks the "Save" button, and sees immediate confirmation. The "last saved" timestamp updates to reflect the manual save time.

**Acceptance Scenarios**:

1. **Given** a user clicks the "Save" button explicitly, **When** the save completes, **Then** a manual checkpoint is created and the UI confirms the save.
2. **Given** a user has no unsaved changes, **When** they view the design title area, **Then** the last modification timestamp is displayed (e.g., "Last saved: 2 minutes ago").

---

### Edge Cases

- **OAuth provider downtime**: If an OAuth provider is unavailable during sign-in, the application displays a user-friendly error message suggesting the user try a different provider.
- **Concurrent sessions (same design)**: If the same user edits a design from two devices simultaneously, the most recent write wins (last-write-wins). Future versions (v1.1+) will add conflict resolution.
- **Token refresh failure**: If the automatic token refresh fails, the user is logged out gracefully with a "Session expired" message and redirected to sign in again.
- **Missing email from OAuth profile**: If the OAuth provider does not return an email, the system falls back to using the provider ID and display name to create the account.
- **Large designs (up to 1000×1000 grids)**: Design data storage must handle stitch data up to 1000×1000 grid sizes without performance degradation.
- **Database connection loss during save**: If the database is unreachable during a save (autosave or manual), the system retries with exponential backoff and shows an error to the user after 3 failures.
- **User with thousands of designs**: Pagination ensures design listing performance remains consistent regardless of the total number of user designs.
- **Unauthorized design access**: Any attempt to access, modify, or delete another user's design is blocked and logged.
- **Rapid editing during autosave**: Debounce timer ensures at most one save per 30-second quiet period; new edits during an in-progress save are queued, not dropped.
- **Offline editing**: Edits made while offline remain in the application's memory and are synchronized automatically when connectivity is restored. The cloud-persisted version is always the source of truth.
- **Browser crash during autosave transaction**: If a crash occurs mid-save, the database transaction rolls back and the previous successfully autosaved version is retained intact.
- **Rate limit exceeded during autosave**: If the user's write rate limit is exceeded (unlikely with 30-second debounce), the autosave retry mechanism handles it identically to a network error — retry with exponential backoff.

## Requirements *(mandatory)*

### Functional Requirements

#### Authentication

- **FR-001**: System MUST allow users to sign in using OAuth social providers: Google, Facebook, Apple, and Microsoft accounts.
- **FR-002**: System MUST NOT support username/password authentication; OAuth is the sole authentication method.
- **FR-003**: System MUST create a new user account on first-time OAuth sign-in, capturing email (if available) and display name from the provider profile. Each OAuth provider identity creates a distinct account; signing in with a different provider (even with the same email) creates a separate account.
- **FR-004**: System MUST link returning users to their existing account when they sign in with the same OAuth provider and identity. Cross-provider account linking is not supported in this version.
- **FR-005**: System MUST store access tokens only in memory within the client application (never in browser local storage or cookies accessible to scripts).
- **FR-006**: System MUST automatically refresh expired access tokens using a refresh mechanism, transparent to the user, with access tokens expiring after 24 hours and refresh credentials after 30 days.
- **FR-007**: System MUST prompt the user to re-authenticate when the refresh credential expires.
- **FR-008**: System MUST allow users to sign out, terminating their session completely.
- **FR-008a**: System MUST present a sign-in wall to unauthenticated users; no application content or features are accessible without authentication.

#### Design CRUD

- **FR-009**: System MUST allow authenticated users to create new designs, associating each design with the creating user's identity.
- **FR-010**: System MUST return only designs owned by the requesting user when listing designs, paginated with a default of 20 designs per page.
- **FR-011**: System MUST return full design data (stitch data, palette, symbol map, metadata) when an authenticated user requests a specific design they own.
- **FR-012**: System MUST allow authenticated users to update designs they own, refreshing the modification timestamp on each update.
- **FR-013**: System MUST soft-delete designs (set a deleted flag and record deletion timestamp) rather than permanently removing them when a user deletes a design.
- **FR-013a**: System MUST provide a "Recently Deleted" view where users can see their soft-deleted designs and restore them within 30 days of deletion.
- **FR-013b**: System MUST permanently purge soft-deleted designs that are older than 30 days. Purged designs are not recoverable.
- **FR-014**: System MUST return a "Forbidden" response and log the attempt when an authenticated user tries to access or modify a design they do not own.
- **FR-015**: System MUST return an "Unauthorized" response when an unauthenticated user attempts any design operation.

#### Design Metadata

- **FR-016**: Each design MUST store the following metadata: unique identifier, owner user identifier, title (default "Untitled Design"), width (stitch count), height (stitch count), stitch data, colour palette, symbol map, uploaded image reference (optional), creation timestamp, modification timestamp, and soft-delete flag (default false).
- **FR-016a**: System MUST validate design metadata on creation and update: title must be 1–255 characters; width and height must each be between 1 and 1000 stitches (inclusive). Requests with values outside these bounds MUST be rejected with a validation error.

#### Design Library Features

- **FR-017**: System MUST allow users to search their designs by title.
- **FR-018**: System MUST allow users to sort their design library by name, creation date, or last modified date.
- **FR-019**: System MUST allow users to filter their design library by colour count (number of colours used in the palette).
- **FR-020**: System MUST display a thumbnail preview for each design in the library listing.

#### Autosave

- **FR-021**: System MUST automatically save the user's design edits 30 seconds after the last edit (debounced).
- **FR-022**: System MUST reset the autosave timer with each new edit so that saves occur only after 30 seconds of inactivity.
- **FR-023**: System MUST queue new edits made during an in-progress autosave for the next autosave cycle, preventing concurrent save requests.
- **FR-024**: System MUST display a "Saving..." indicator while an autosave is in progress.
- **FR-025**: System MUST display "All changes saved" with a checkmark icon for 2 seconds after a successful autosave.
- **FR-026**: System MUST retry failed autosave requests up to 3 times with exponential backoff (1s, 2s, 4s).
- **FR-027**: System MUST display "Changes not saved - retry?" with an alert icon after all autosave retries are exhausted.
- **FR-028**: System MUST show a browser confirmation dialog when the user attempts to close a tab with unsaved changes.

#### Draft Recovery

- **FR-029**: System MUST retain the last successfully autosaved version of a design when a browser crash occurs.
- **FR-030**: System MUST load the last autosaved state when a user reopens a design after a crash or session loss.
- **FR-031**: System MUST keep pending edits in application memory during network outages and synchronize them automatically when connectivity returns.

#### Manual Save

- **FR-032**: System MUST allow users to explicitly save their design via a "Save" button, creating a manual checkpoint.
- **FR-033**: System MUST display the last modification timestamp (e.g., "Last saved: 2 minutes ago") in the design title area when the user has no unsaved changes.

#### Data Retention

- **FR-034**: System MUST retain all designs indefinitely until explicitly deleted by the user.

#### Rate Limiting

- **FR-035**: System MUST enforce per-user rate limits on design API operations: a maximum of 60 read requests per minute and 30 write requests per minute.
- **FR-036**: System MUST return a standard rate-limit-exceeded response when a user exceeds the allowed request rate, without blocking other users.

### Key Entities

- **User**: Represents an authenticated individual. Key attributes: unique identifier, email (optional), display name, OAuth provider identifier, account creation timestamp. A user owns zero or more designs.
- **Design**: Represents a cross-stitch pattern created by a user. Key attributes: unique identifier, owner (user), title, dimensions (width/height in stitch count), stitch data (grid of colour/symbol assignments), colour palette, symbol map, uploaded source image reference (optional), creation timestamp, modification timestamp, soft-delete flag, deletion timestamp (nullable). A design belongs to exactly one user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the full sign-in flow (click "Sign in" → OAuth consent → return to app as authenticated user) in under 30 seconds.
- **SC-002**: 70% of first-time users successfully sign in and create their first design in a single session.
- **SC-003**: Users can create, view, edit, and delete designs with each operation completing in under 2 seconds from the user's perspective.
- **SC-004**: Design library listing supports at least 1,000 designs per user without noticeable performance degradation (page loads in under 2 seconds).
- **SC-005**: Autosave completes within 2 seconds (at the 95th percentile) after the 30-second debounce period elapses.
- **SC-006**: After a browser crash, 100% of last-autosaved design state is recoverable when the user reopens the application.
- **SC-007**: Users lose at most 30 seconds of work in any crash or failure scenario.
- **SC-008**: Autosave status indicator updates correctly (Saving → Saved → Error) in 100% of autosave cycles.
- **SC-009**: Zero unauthorized design access succeeds — all cross-user access attempts are blocked and logged.
- **SC-010**: 40% of users who sign in during the first week return within 30 days (retention baseline).

## Assumptions

- At least one OAuth provider (Google) will be configured and operational at launch; the remaining three providers (Facebook, Apple, Microsoft) are stretch goals for the initial release.
- The application follows a last-write-wins conflict resolution strategy for concurrent edits from multiple devices; conflict detection and merge are deferred to v1.1+.
- Design version history (rollback to previous autosaves) is out of scope for this feature and deferred to v1.1+.
- Account deletion and GDPR data export workflows are out of scope and deferred to v1.1+.
- Design sharing (public links, collaboration) is out of scope and deferred to v1.1+.
- Cross-provider account linking (merging accounts that share the same email across different OAuth providers) is out of scope and deferred to v1.1+.
- The application infrastructure (database, cloud hosting) from Feature 0 is provisioned and operational before this feature begins.
- OAuth client secrets and other sensitive credentials are stored in a secure secrets management service, never in application code.

## Dependencies

- **Feature 0 (Infrastructure Setup)**: Database must be provisioned, cloud hosting operational, and secrets management configured.
- **External**: OAuth identity provider must be configured with social provider integrations.
- **External**: Cloud database must have read/write permissions enabled for the application.
- **External**: Secrets management service must be accessible for OAuth client credentials.

## Blocked Features

- **Feature 2 (Core Editor)**: Requires design CRUD to persist canvas edits.
- **Feature 3 (Content Generation)**: Requires design ownership to attach uploaded images.
- **Feature 4 (Export)**: Requires design data to generate exports.
