# Stitches Features

This directory contains the feature breakdown for the Stitches cross-stitch pattern design application. Features are organized by implementation priority and dependency relationships.

## Source Documents

- **[Business Requirements Document (BRD)](../docs/BRD.md)** - Business objectives and success metrics
- **[Product Requirements Document (PRD)](../docs/PRD.md)** - User stories and acceptance criteria
- **[Software Design Document (SDD)](../docs/SDD.md)** - Technical architecture and implementation design
- **[Project Constitution](../.specify/memory/constitution.md)** - Governing principles and mandatory tech choices

## Feature Overview

### [00-infrastructure](./00-infrastructure/) (Priority: P0 - Foundation)

**Status:** Not Started  
**Dependencies:** None  
**Blocks:** All other features

**User Stories:**
- 0.1: Frontend Development Environment Setup (React + Vite)
- 0.2: Backend Development Environment Setup (ASP.NET Core 10+)
- 0.3: Azure Deployment Infrastructure (IaC + CI/CD)

**What this enables:**
- Local development environment for frontend and backend
- Azure infrastructure provisioned and ready
- CI/CD pipeline for automated deployments
- Development, staging, and production environments

---

### [01-auth-persistence](./01-auth-persistence/) (Priority: P1 - Foundation)

**Status:** Not Started  
**Dependencies:** Feature 0 (Infrastructure)  
**Blocks:** Features 2, 3, 4

**User Stories from PRD:**
- Story #5: User Authentication & Design Storage
- Story #4: Autosave & Draft Recovery

**What this enables:**
- Users can log in with OAuth (Google, Facebook, Apple, Microsoft)
- Designs are persisted to Azure SQL Database
- Cloud-based storage across devices
- Automatic save every 30 seconds
- Draft recovery after browser crash

---

### [02-core-editor](./02-core-editor/) (Priority: P1 - Core Value)

**Status:** Not Started  
**Dependencies:** Feature 1 (Auth & Persistence)  
**Required for:** Features 3, 4

**User Stories from PRD:**
- Story #2: Interactive Pattern Editor
- Story #7: Colour Palette & Symbols

**What this enables:**
- Manual pattern creation from scratch
- Interactive grid with stitch editing
- 200+ DMC thread colours with symbol assignments
- Undo/redo, zoom, fractional stitches
- Real-time colour legend generation

---

### [03-content-generation](./03-content-generation/) (Priority: P2 - Enhanced Input)

**Status:** Not Started  
**Dependencies:** Feature 2 (Core Editor)  
**Can develop in parallel with:** Feature 4

**User Stories from PRD:**
- Story #1: Photo Import & Auto-Conversion
- Story #3: Lettering (Text to Stitches)

**What this enables:**
- Quick pattern creation from photos
- Photo-to-grid conversion with DMC colour mapping
- Text personalization (names, dates, messages)
- Google Fonts integration
- Ability to refine auto-generated content

---

### [04-export](./04-export/) (Priority: P2 - Output)

**Status:** Not Started  
**Dependencies:** Feature 2 (Core Editor)  
**Can develop in parallel with:** Feature 3

**User Stories from PRD:**
- Story #6: Export to PDF & PNG

**What this enables:**
- High-quality PDF generation for printing
- 300 DPI PNG for digital sharing
- Pattern grid with colour legend and stitch count
- Completion of create→edit→export workflow

---

## Implementation Sequence

### Phase 0: Infrastructure (Must Complete First)
```
Feature 0: Infrastructure Setup
├── Frontend environment
├── Backend environment
└── Azure deployment pipeline
```
**Checkpoint:** Dev environments working, Azure infrastructure provisioned

---

### Phase 1: Foundation (Sequential)
```
Feature 0 ────► Feature 1: Auth & Persistence
                └─► Authentication working
                └─► Design CRUD operational
                └─► Autosave functional
```
**Checkpoint:** Users can log in, create designs, and autosave works

---

### Phase 2: Core Experience (Sequential)
```
Feature 1 ────► Feature 2: Core Editor
                └─► Canvas rendering
                └─► Stitch editing
                └─► Palette management
```
**Checkpoint:** Users can manually create and edit patterns (MVP!)

---

### Phase 3: Content & Output (Parallel)
```
Feature 2 ────┬─► Feature 3: Content Generation
              │   └─► Photo import
              │   └─► Lettering
              │
              └─► Feature 4: Export
                  └─► PDF generation
                  └─► PNG generation
```
**Checkpoint:** Full workflow - import → edit → export

---

## Dependency Graph

```
┌─────────────────────────────────────┐
│  Feature 0: Infrastructure (P0)     │
│  - Frontend setup                   │
│  - Backend setup                    │
│  - Azure deployment                 │
└──────────────┬──────────────────────┘
               │ BLOCKS ALL
               ▼
┌─────────────────────────────────────┐
│  Feature 1: Auth & Persistence (P1) │
│  - OAuth login                      │
│  - Design storage                   │
│  - Autosave                         │
└──────────────┬──────────────────────┘
               │ REQUIRED FOR
               ▼
┌─────────────────────────────────────┐
│  Feature 2: Core Editor (P1)        │
│  - Interactive canvas               │
│  - Colour palette                   │
│  - Symbol management                │
└──────────┬──────────────────────────┘
           │ REQUIRED FOR
           │
     ┌─────┴─────┐
     │           │
     ▼           ▼
┌──────────┐  ┌──────────┐
│Feature 3 │  │Feature 4 │
│Content   │  │Export    │
│(P2)      │  │(P2)      │
└──────────┘  └──────────┘
```

---

## Development Strategy

### MVP-First Approach (Recommended)
1. **Complete Feature 0** → Infrastructure ready
2. **Complete Feature 1** → Users can authenticate and save designs
3. **Complete Feature 2** → Users can manually create patterns ✅ **MVP ACHIEVED**
4. **Validate with beta users** → Gather feedback on core editor
5. **Add Feature 3 OR 4** → Based on user feedback priority
6. **Complete remaining features** → Full feature set

### Parallel Team Strategy
If multiple developers available:
1. **All hands on Feature 0** → Complete infrastructure together
2. **Team splits after Feature 1 complete:**
   - Team A: Feature 3 (Content Generation)
   - Team B: Feature 4 (Export)
3. **Both teams can work in parallel** → Merge when ready

---

## Success Criteria by Feature

### Feature 0 Success
- ✅ Frontend dev server runs locally
- ✅ Backend API runs locally
- ✅ Azure resources provisioned via IaC
- ✅ CI/CD pipeline deploys to staging

### Feature 1 Success
- ✅ Users can log in with OAuth
- ✅ Designs CRUD operations work
- ✅ Autosave triggers every 30 seconds
- ✅ Draft recovery after browser crash

### Feature 2 Success (MVP)
- ✅ Users can create blank canvas
- ✅ Users can add/remove stitches
- ✅ Colour palette works with 200+ DMC colours
- ✅ Undo/redo functional
- ✅ 60 FPS at 100×100 grid

### Feature 3 Success
- ✅ Photo upload and conversion < 10 seconds
- ✅ User satisfaction ≥ 4/5 on conversion quality
- ✅ Text rendering with Google Fonts
- ✅ Rasterized content can be refined

### Feature 4 Success
- ✅ PDF export < 5 seconds
- ✅ PDF includes grid, legend, stitch count
- ✅ PNG exports at 300 DPI
- ✅ Export completes end-to-end workflow

---

## Alignment with Constitution

All features adhere to the [Project Constitution](../.specify/memory/constitution.md):

- **Cloud-First Architecture:** Feature 1 ensures all designs persist to Azure
- **Accessibility & Simplicity:** Feature 2 focuses on low cognitive load editing
- **User-Centric Quality:** Feature 3 targets ≥ 4/5 satisfaction
- **Security & Privacy-First:** Feature 1 implements OAuth-only auth
- **Performance-First Design:** All features target constitution SLOs

**Mandatory Tech Stack Compliance:**
- Frontend: React + Vite ✓
- Backend: ASP.NET Core 10+ ✓
- Database: Azure SQL Database ✓
- Storage: Azure Blob Storage ✓
- Auth: OAuth 2.0 (delegated) ✓
- Testing: Vitest (frontend), xUnit + NSubstitute (backend) ✓

---

## Getting Started

1. **Read the source documents** (BRD, PRD, SDD, Constitution)
2. **Start with Feature 0** - No exceptions, infrastructure comes first
3. **Review user stories** in each feature folder's `user-stories.md`
4. **Follow acceptance criteria** from the PRD for each story
5. **Validate at checkpoints** before moving to next feature

---

**Last Updated:** 2026-01-31  
**Total User Stories:** 10 (3 infrastructure + 7 from PRD)  
**Total Features:** 5 (ordered 00-04 by implementation sequence)
