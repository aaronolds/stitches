# Cross Stitch Pattern Design Website – Product Requirements Document

## 1. Executive Summary

### Problem Statement

Professional cross-stitch pattern design tools are expensive, desktop-bound, and lack cloud persistence. Amateur enthusiasts lack accessible, modern tools to design patterns from photos or scratch, save progress, and export designs for manufacture or sharing.

### Proposed Solution

A modern, web-based cross-stitch pattern design application that enables users to import photos, create/edit patterns on an interactive grid, add lettering, manage colours and symbols, autosave designs to the cloud, and export as PDF/PNG. Built on Azure with OAuth 2.0 authentication, the platform provides a scalable, accessible alternative to desktop tools.

### Success Criteria

- **User Onboarding**: New users can create & export their first pattern within 10 minutes.
- **Pattern Conversion Accuracy**: Uploaded photos convert to recognizable cross-stitch patterns (user satisfaction ≥ 4/5).
- **Uptime**: 99.5% monthly availability in production.
- **Adoption**: 500+ registered users by the end of MVP build.
- **Performance**: Pattern save/autosave completes in < 2 seconds (p95).
- **First-Session Success**: 70% of new users complete a first design within their first session.
- **Retention**: 40% of users return within 30 days after creating their first design.
- **Editing Responsiveness**: < 5 seconds average response time for standard editing actions (excluding background image processing).

---

## 2. User Experience & Functionality

### User Personas

1. **Emma** (Amateur Hobbyist)
   - Uses cross-stitch as a hobby, not professional income.
   - Owns 2–3 cross-stitch hoops; hand-embroiders for friends/family.
   - Comfortable with computer but not a power user.
   - Wants to transform holiday photos into quick cross-stitch gifts.
   - Pain point: Desktop tools are overkill; free online tools lack polish.

2. **Maya** (Small Business Owner)
   - Designs cross-stitch patterns for a small Etsy shop.
   - Assembles 10–20 designs/month; sells kits to customers.
   - Wants to store historical designs and version them.
   - Pain point: Needs affordable, cloud-backed tool; file management is chaotic.

3. **Alex** (Casual Experimenter)
   - Tried cross-stitch once; curious but not committed.
   - Wants to freehand draw patterns without photo upload.
   - Pain point: Tool complexity is a barrier to entry.

### User Stories & Acceptance Criteria

#### Story 1: Photo Import & Auto-Conversion

**As** a hobbyist, **I want to** upload a JPEG/PNG photo and have it automatically converted to a cross-stitch grid, **so that** I can quickly turn a memory into a pattern.

**Acceptance Criteria:**

- Upload button accepts JPEG/PNG files up to 10 MB.
- System resizes photo to a configurable stitch count (default: 100×100 stitches).
- Colours are mapped to a standard thread palette (e.g., DMC).
- Conversion completes in < 10 seconds (UI shows progress).
- Result is editable (user can refine the auto-conversion).
- Unsuccessful conversions show a user-friendly error message.

---

#### Story 2: Interactive Pattern Editor

**As** a designer, **I want to** manually add/remove stitches, choose colours, draw lines and backstitches, and undo/redo, **so that** I can create or refine patterns with full control.

**Acceptance Criteria:**

- Grid displays at 2–4 zoom levels (50%, 100%, 200%, 400%).
- Colour palette shows ≥ 200 thread colours with symbol assignment.
- Left-click adds a stitch; right-click removes.
- Undo/redo support for ≥ 50 actions.
- Drag-to-select multiple stitches and bulk-colour them.
- Fractional stitch support (half-stitches, quarter-stitches).
- Keyboard shortcuts for common tools (e.g., `U` = undo, `Z` = zoom).

---

#### Story 3: Lettering (Text to Stitches)

**As** a user, **I want to** add text anywhere on my canvas in any web font (e.g., Google Fonts), **so that** I can personalize designs with names, dates, or messages.

**Acceptance Criteria:**

- Text insertion creates a text box on the canvas.
- Font picker offers ≥ 50 Google Fonts.
- Font size and rotation are adjustable.
- Text is automatically rasterized to cross-stitch grid.
- Rasterized text can be further edited stitch-by-stitch.
- User can delete or edit the text layer.

---

#### Story 4: Autosave & Draft Recovery

**As** a designer, **I want** my changes to autosave every 30 seconds, **so that** I don't lose work if my browser crashes.

**Acceptance Criteria:**

- Autosave triggers every 30 seconds (visible icon indicator).
- If browser crashes, reopening the app restores the last saved draft.
- Autosaved draft is retained for ≥ 7 days.
- User can manually save a checkpoint (snapshot).
- Current draft title and modification timestamp are visible.

---

#### Story 5: User Authentication & Design Storage

**As** a returning user, **I want to** log in with my Google/Facebook/Apple account and access my saved designs, **so that** I can manage my portfolio and work across devices.

**Acceptance Criteria:**

- Login supports Google, Facebook, Apple ID, and Microsoft accounts (OAuth 2.0).
- First login creates a user account with minimal profile data (email, display name).
- Authenticated users can create, view, edit, and delete designs.
- Each design stores metadata: title, size (stitch count), creation date, last modified, colour count, thumbnail.
- Design listing shows search/sort by name, date, or colour count.
- Unauthenticated users see a login prompt; demo mode is not available.

---

#### Story 6: Export to PDF & PNG

**As** a maker, **I want to** export my pattern as a high-quality PDF (for printing) or PNG (for sharing), **so that** I can produce my design or share it digitally.

**Acceptance Criteria:**

- Export dialog offers PDF and PNG options.
- PDF includes the pattern grid, colour legend, and stitch count.
- PDF is optimized for printing at common sizes (A4, letter, 8×10").
- PNG is 300 DPI minimum; background is white.
- PNG includes a legend as an overlay or separate file.
- Export completes within 5 seconds.
- File naming is user-configurable (default: `{design_title}_{timestamp}`).

---

#### Story 7: Colour Palette & Symbols

**As** a user, **I want to** see a curated palette of thread colours (with symbols), and optionally customize symbols or colours, **so that** my charts are clear and reflect my thread stash.

**Acceptance Criteria:**

- Default palette includes ≥ 200 DMC thread colours.
- Each colour is assigned a unique symbol (letters, numbers, or patterns).
- Colour legend is auto-generated and displayed/exported with the pattern.
- Users can edit a colour's symbol or swap a colour for a similar one.
- Changes to the palette update the entire pattern instantly.

---

### Non-Goals (MVP)

- **Sharing**: Public links, galleries, or social sharing — deferred to v1.1.
- **Collaboration**: Real-time co-editing or comments — deferred to v2.0.
- **Advanced AI Features**: Generative art, pattern suggestions — deferred to v2.0.
- **Mobile App**: iOS/Android native apps; PWA only for MVP.
- **Premium Tiers**: All features are free in MVP; monetization deferred to v1.1.
- **Bulk Upload**: Uploading multiple photos at once — deferred to v1.1.

---

## 3. Technical Specifications

### Architecture Overview

The application follows a **client–server (SPA + REST API)** architecture:

```
┌─────────────────────────────────┐
│     Browser (React SPA)         │
│  (Canvas, Editor, Forms)        │
└────────────┬────────────────────┘
             │ HTTPS (REST API)
             ▼
┌─────────────────────────────────┐
│  API Layer (Node.js/Express)    │
│  • Auth (JWT validation)        │
│  • Design CRUD                  │
│  • Image processing (async)     │
└────────────┬────────────────────┘
             │
    ┌────────┼────────┐
    ▼        ▼        ▼
┌─────────────────────────────────────┐
│  Data & Storage (Azure)             │
│  • SQL Database (designs, users)    │
│  • Blob Storage (uploaded photos)   │
│  • Key Vault (secrets)              │
└─────────────────────────────────────┘
```

### Core Components

#### Frontend (React)

- **Canvas Component**: Grid rendering, zoom, interactive editing.
- **Editor UI**: Colour palette, tool palette, layers panel.
- **Auth Flow**: OAuth redirect, token storage (secure httpOnly cookie).
- **State Management**: Redux or Context API for design data.
- **Tooling**: Vite for build, Vitest for unit tests.

#### Backend (Node.js + Express)

- **Authentication**: JWT validation middleware; delegated to Auth0 or Azure AD B2C.
- **Design API**:
  - `POST /designs` — create new design.
  - `GET /designs/:id` — fetch design (with ownership check).
  - `PATCH /designs/:id` — update design; autosave endpoint.
  - `DELETE /designs/:id` — delete design.
  - `GET /designs` — list user's designs (paginated).
- **Image Processing**:
  - `POST /upload/convert` — async job to convert photo to grid (Job ID returned immediately).
  - `GET /upload/status/:jobId` — poll for completion.
- **Export API**:
  - `POST /export/pdf` — generate PDF.
  - `POST /export/png` — generate PNG.

#### Database (Azure SQL Database)

- **Schema**:

  ```sql
  Users (id, email, displayName, provider, providerId, createdAt)
  Designs (id, userId, title, width, height, stitchData [JSON], 
           uploadedImageUrl, createdAt, updatedAt, isDeleted)
  ```

- **Indexing**: Foreign key on `Designs.userId`, createdAt/updatedAt for sorting.
- **Backup**: Automated daily backups retained for 7 days.

#### Storage (Azure Blob Storage)

- **Uploaded Photos**: `{userId}/{designId}-original.jpg`.
- **Exports (optional cache)**: `{userId}/{designId}-export-{timestamp}.pdf`.
- **Lifecycle**: Delete blobs > 90 days old (user cleanup).

#### Background Jobs (Azure Functions or App Service Worker)

- Image resizing and colour-mapping logic.
- PDF/PNG generation for large exports.
- Email notifications (future).

### Integration Points

| System | Purpose | Notes |
|--------|---------|-------|
| **Auth0 / Azure AD B2C** | OAuth 2.0 / OIDC provider | Returns JWT; frontend stores in secure cookie. |
| **Google Fonts API** | Font availability | Static list; no real-time API calls. |
| **Azure App Service** | Compute (frontend + API) | 2+ instances in production for HA. |
| **Azure SQL Database** | Relational data | Zone-redundant backup recommended. |
| **Azure Blob Storage** | Static content (images, exports) | RA-GRS (read-access geo-redundant). |
| **Azure Key Vault** | Secrets management | Store: DB connection string, storage account key, OAuth client secret. |
| **Azure CDN** | Static asset delivery | Cache React bundle, fonts. |

### Security & Privacy

- **HTTPS**: All traffic is TLS 1.2+.
- **Authentication**: OAuth 2.0 with third-party providers (no password storage).
- **Authorization**: User can only view/edit their own designs (checked server-side).
- **Secrets**: All secrets (DB connection, storage keys, OAuth secret) stored in Azure Key Vault, injected at runtime.
- **Data Isolation**: Uploaded images are stored in user-scoped blob paths.
- **Data Retention**: Designs and uploaded images are retained indefinitely unless the user deletes them.
- **Compliance**: GDPR compliance posture documented; CCPA/GDPR-compliant data deletion implemented in v1.1.

### Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| **Page load time** | < 2s (p95) | React bundle cached; CDN'd. |
| **Canvas render** | 60 FPS at 100×100 grid | WebGL or Canvas 2D optimization. |
| **Design autosave** | < 2s (p95) | Debounced API call; optimistic UI update. |
| **Photo conversion** | < 10s (p95) | Async job; user sees progress bar. |
| **Export (PDF/PNG)** | < 5s (p95) | Pre-generated or streamed. |
| **API latency** | < 200ms (p95) | Excluding image processing. |

---

## 4. Risks & Roadmap

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Photo-to-pattern conversion quality** | User dissatisfaction if output is poor | MVP includes manual refinement; quality settings (e.g., posterization) in UI. Gather user feedback in beta. |
| **Database scale** | Slow queries at 10k+ users; storage cost | Index `userId`, `createdAt`; implement pagination (default 20 designs/page). Archive old designs v1.1. |
| **Blob Storage cost** | Unexpected Azure bills for large files | Enforce 10 MB upload limit; lifecycle policies to delete exports. Monitor costs weekly. |
| **Canvas performance on mobile** | Users on older devices experience lag | Test on iPad; consider rendering optimizations (LOD, culling) for Q2. |
| **OAuth provider downtime** | Users cannot log in | Failover to email/password auth (v1.1); document incident procedure. |
| **Image processing job failures** | Lost user uploads | DLQ (dead-letter queue) for failed jobs; email user with retry link. |

### Phased Rollout

#### **MVP (8–12 weeks) — "Launch"**

- Core features: photo import, editor, autosave, auth, export (PDF/PNG).
- Single Azure region (East US).
- Limited to 10k concurrent users (single App Service instance + vertical scaling).
- **Release criteria**:
  - 50 beta users, ≥ 4/5 satisfaction on photo conversion.
  - All acceptance criteria pass.
  - Uptime ≥ 99% in staging for 2 weeks.

#### **v1.1 (2–4 weeks) — "Stability & Scale"**

- Sharing (public links, PDF embed).
- Social login improvements; email/password fallback.
- Multi-region failover (production).
- Archive old designs; cleanup blobs.
- Mobile PWA optimization.
- **Target**: 50k concurrent users.

#### **v2.0 (TBD) — "Community & Creation"**

- Collaboration (real-time co-editing, comments).
- Pattern gallery, discovery, recommendations.
- Design marketplace (monetization).
- Advanced features: pattern stitching suggestions, AI-generated palettes.
- **Target**: 1M users, revenue model.

### Constraints & Assumptions

| Assumption | Rationale | Review Date |
|------------|-----------|-------------|
| Team size: 2–3 devs | Aggressive timeline; assumes high velocity. | Q1 mid-point (Jan 2026) |
| Q1 launch date | 3-month sprint; non-negotiable. | Revisited weekly. |
| OAuth-only auth (MVP) | Reduces complexity; delegated to trusted provider. | Post-launch feedback. |
| Single Azure region (MVP) | Reduces DevOps overhead; plan multi-region v1.1. | Post-launch. |
| Colour count ≤ 500 | Limits palette size for UX/performance. | Monitor user feedback. |
| No mobile app (MVP) | PWA covers mobile; native apps deferred to v1.1. | Post-MVP user survey. |

---

## 5. Success Metrics & Go/No-Go Criteria

### Go-Live Criteria (MVP)

- ✅ All acceptance criteria for Stories 1–7 pass automated tests.
- ✅ Manual QA: 50 beta users report ≥ 4/5 satisfaction on core features.
- ✅ Performance: 99%+ of autosaves complete in < 2s; 99%+ of exports in < 5s.
- ✅ Security: OAuth flow tested; no secrets in logs; SSL cert valid.
- ✅ Capacity: Tested with 100 concurrent users; API and DB stable.

### Post-Launch Metrics (Track Weekly)

- **User Adoption**: Registered users, DAU/MAU, retention (day 7, day 30).
- **Feature Usage**: % users who upload photos vs. freehand-draw; export conversion rate.
- **Performance**: API latency (p50, p95, p99), canvas FPS, export times.
- **Quality**: Photo conversion satisfaction, error rate, support tickets.
- **Infrastructure**: Azure cost (target < $2k/month MVP phase), uptime %.

---

## Appendix: Glossary

- **Autosave**: Periodic server-side save of design state, triggered automatically without user action.
- **Backstitch**: A reinforcement stitch overlaid on cross-stitches; represented as a line in the grid.
- **Blob Storage**: Azure's object storage service for unstructured data (images, documents).
- **Conversion**: The process of mapping a photo's pixels to cross-stitch grid cells and colours.
- **DMC**: A standard thread colour numbering system widely used by cross-stitch creators.
- **Fractional stitch**: A partial stitch (e.g., ¼, ½) used for detail and contours.
- **Grid**: The canvas divided into square cells; one cell = one stitch.
- **JWT**: JSON Web Token; a secure, stateless credential issued by OAuth provider.
- **OAuth 2.0**: An open standard for delegated authentication (login via Google, Facebook, etc.).
- **Palette**: A set of thread colours available for the design.
- **SPA**: Single-Page Application; a web app that dynamically updates content without full page reloads.
- **Symbol**: A unique character or pattern assigned to each colour; printed in the legend.

---

**Document Version**: 1.0  
**Last Updated**: January 25, 2026  
**Owner**: Product Team  
**Status**: Approved for MVP Development
