# Cross Stitch Pattern Design Website – Business Requirements Document

## Document Control

- **Owner:** Product Management
- **Status:** Draft
- **Version:** 0.1
- **Last Updated:** 2026-01-31

## Purpose

Define the business requirements for a web‑based cross‑stitch pattern design application, including objectives, scope, and success criteria to guide delivery and stakeholder alignment.

## Business Problem & Opportunity

Hobbyist crafters lack a modern, web‑based tool that combines photo‑to‑pattern conversion, flexible lettering, and cloud‑based design storage. Existing desktop tools are powerful but less accessible, while web tools are often limited in editing and export capabilities. A modern, cloud‑backed solution can expand access, enable retention through accounts, and create a foundation for future sharing and community features.

## Stakeholders

- **Executive Sponsor:** TBD
- **Product Owner:** TBD
- **Engineering Lead:** TBD
- **Design/UX Lead:** TBD
- **Security/Compliance:** TBD
- **Customer Support/Operations:** TBD

## Business Objectives

- Deliver a modern, web‑based pattern design experience that reduces time to create a usable pattern.
- Increase user retention through cloud‑saved designs and reliable autosave.
- Enable future monetization or community expansion via scalable architecture and account‑based access.

## Success Metrics

- 70% of new users complete a first design within their first session.
- 40% of users return within 30 days after creating their first design.
- 99.5% monthly availability for the application.
- < 5 seconds average response time for standard editing actions (excluding background image processing).

## Scope

### In Scope (MVP)

- Web‑based design canvas with photo import and grid editing tools.
- Text insertion with web fonts and conversion to a stitch grid.
- Colour palette with symbols and exportable legend.
- Export to PDF and PNG.
- User authentication via social login and cloud‑saved designs.
- Autosave and restore of drafts.

### Out of Scope (Initial Release)

- Public sharing, comments, likes, or social feeds.
- In‑app marketplace for patterns.
- Native mobile applications.

## Assumptions

- Users have access to modern browsers on desktop or mobile.
- Third‑party identity providers are available and stable for OAuth/OIDC.
- A standard thread colour palette is acceptable for MVP.

## Constraints

- Default image upload size limited to 10 MB for performance and cost control.
- Sensitive configuration must be stored in a managed secrets store.
- Background image processing must not block editing workflows.

## Risks

- Photo‑to‑pattern conversion quality may not meet user expectations without manual controls.
- Image processing load could increase costs or degrade performance at scale.
- OAuth provider changes could affect authentication reliability.

## Dependencies

- Identity provider configuration (Auth0 or Azure AD B2C).
- Azure App Service, Azure SQL Database, and Azure Blob Storage availability.
- Font hosting (Google Fonts or equivalent CDN).

## Functional Requirements

### Pattern Creation Features

- **Photo import:** Users must be able to upload images (JPEG/PNG). The system will convert the image into a cross‑stitch grid by resizing it to a specified number of stitches and mapping colours to the nearest thread palette.
- **Max upload size:** Default maximum size is 10 MB, adjustable after performance testing.
- **Drawing/editing tools:** Users can add/remove stitches on a grid, choose colours, draw lines and backstitch, and undo/redo. The interface should support fractional stitches.
- **Lettering:** Users can insert text anywhere on the canvas. The application must render text using any web font and convert it into a cross‑stitch grid.
- **Colour palette & symbols:** Provide a large library of thread colours and assign symbols to each colour. Users can change a symbol or colour manually. Exported charts include a legend.
- **Export:** Designs can be exported as PDF or PNG.
- **Autosave & restore:** Changes autosave so users do not lose progress. Drafts are stored in the database with periodic autosave.

### User Accounts & Persistence

- **Authentication:** Users register and log in via OAuth 2.0 / OpenID Connect with Google, Facebook, Apple ID, and Microsoft accounts through a hosted identity service. Only minimal profile data is stored.
- **Design storage:** Users can create, edit, and delete designs. Each design includes metadata, design grid data, and references to uploaded images stored in Blob Storage.
- **User settings:** Users can configure default grid sizes, preferred thread palettes, and favourite fonts.

### Collaboration & Sharing (Future)

- **Sharing:** Not included in the initial release.
- **Comments/likes:** Not included in the initial release.

## Non‑Functional Requirements

- **Scalability:** Support concurrent users via horizontal scaling.
- **Performance:** Image processing runs asynchronously to keep the UI responsive.
- **Availability & reliability:** Deploy across at least two availability zones in production. Use zone‑redundant database and geo‑replicated storage.
- **Security:** Use HTTPS. Protect API endpoints with valid tokens. Store secrets in a managed vault.
- **Compliance & privacy:** Only design owners can access their data unless explicitly shared. Retention is indefinite until deleted by the user.
- **Browser compatibility:** Support modern browsers on desktop and mobile; use PWA techniques for offline access and installation.

## System Architecture (High‑Level)

The application follows a client–server architecture with a single‑page application front‑end and REST/GraphQL APIs hosted in Azure. Image processing is performed asynchronously using background jobs or serverless functions. A reference diagram will be added in a subsequent revision.

## Milestones & Timeline

- **Discovery & validation:** 2–3 weeks
- **MVP build:** 8–12 weeks
- **Beta release:** 2–4 weeks
- **General availability:** TBD based on beta feedback

## Approval & Sign‑Off

- **Executive Sponsor:** ____________________ Date: __________
- **Product Owner:** ________________________ Date: __________
- **Engineering Lead:** ______________________ Date: __________
- **Design/UX Lead:** _______________________ Date: __________
- **Security/Compliance:** ___________________ Date: __________
