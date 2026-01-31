# Feature 2: Core Pattern Editing Canvas

**Priority:** P1 (Core Value Proposition)  
**Status:** Not Started  
**Dependencies:** Feature 1 (Auth & Persistence)  
**Required For:** Features 3, 4

## Overview

This feature delivers the heart of the Stitches application—the interactive cross-stitch pattern editor. Users can manually create patterns from scratch using a grid canvas, choose from 200+ DMC thread colours, manage symbols for each colour, and edit stitches with full control including undo/redo, zoom, and fractional stitches.

**Rationale:**
The pattern editor is the core value proposition per the PRD. Without this, users have no way to create or refine designs. This feature represents the MVP—once complete, users can manually create patterns end-to-end. The colour palette and editor are inseparable: you can't edit stitches without selecting colours, and symbol management is only meaningful in the context of editing.

**What this enables:**
- Manual pattern creation from scratch (blank canvas)
- Fine-grained stitch-by-stitch editing
- Professional-quality colour palette (DMC thread library)
- Symbol assignments for printable charts
- Real-time legend generation
- Undo/redo for mistake correction
- Responsive editing at 60 FPS

---

## User Story 2.1: Interactive Pattern Editor

**(PRD Story #2)**

**As** a designer, **I want to** manually add/remove stitches, choose colours, draw lines and backstitches, and undo/redo, **so that** I can create or refine patterns with full control.

### Priority
**P1** - Core MVP feature

### User Personas
- **Emma** (Amateur Hobbyist): Wants to freehand draw simple patterns (hearts, initials) without complexity
- **Maya** (Small Business Owner): Needs precise editing to refine auto-converted photos for her Etsy shop
- **Alex** (Casual Experimenter): Expects intuitive click-to-edit experience (like drawing on graph paper)

### Why This Priority
This story delivers the minimum viable product. Even without photo import or export, users can manually create patterns, save them (Feature 1), and achieve value. Per the Constitution, "Editing friction compounds" — a responsive, polished editor is mandatory for retention.

### Independent Test
User opens a blank 50×50 grid, selects a colour from the palette, clicks to add 10 stitches forming a simple shape, uses undo to remove 2 stitches, zooms in to 200%, adds fractional stitches, and saves the design (autosave triggers).

---

### Acceptance Criteria (from PRD)

#### 1. Grid Display & Zoom

**Given** a user opens a new blank design  
**When** the canvas loads  
**Then** a grid is displayed with default size 100×100 stitches (configurable in settings)

**Given** the grid is displayed  
**When** the user interacts with zoom controls  
**Then** the grid supports 4 zoom levels: 50%, 100%, 200%, 400%

**Given** the grid is zoomed in  
**When** the canvas exceeds the viewport  
**Then** horizontal and vertical scrolling is enabled

**Given** the user is at 400% zoom  
**When** rendering 100×100 stitches  
**Then** the canvas maintains 60 FPS per Constitution SLO

#### 2. Stitch Editing (Basic)

**Given** a user has a colour selected  
**When** they left-click on an empty grid cell  
**Then** a full cross-stitch in the selected colour is added to that cell

**Given** a user has a stitch in a cell  
**When** they right-click on that cell  
**Then** the stitch is removed (cell returns to empty)

**Given** a user has a colour selected  
**When** they click-and-drag across multiple cells  
**Then** all cells in the drag path are filled with stitches in the selected colour

**Given** a user has the eraser tool selected  
**When** they click-and-drag across stitched cells  
**Then** all stitches in the drag path are removed

#### 3. Drag-to-Select & Bulk Operations

**Given** a user holds Shift and drags a rectangle  
**When** they release the mouse  
**Then** all cells within the rectangle are selected (highlighted)

**Given** multiple cells are selected  
**When** the user applies a colour change  
**Then** all selected stitches change to the new colour instantly

**Given** multiple cells are selected  
**When** the user presses Delete or Backspace  
**Then** all selected stitches are removed

#### 4. Fractional Stitches

**Given** a user selects the "Half-Stitch" tool  
**When** they click on a cell  
**Then** a diagonal half-stitch (/) or (\) is added (user chooses orientation)

**Given** a user selects the "Quarter-Stitch" tool  
**When** they click on a cell corner  
**Then** a quarter-stitch is added in that quadrant (4 corner positions possible)

**Given** a cell has multiple fractional stitches (e.g., two quarters)  
**When** rendered  
**Then** both fractional stitches are visible with correct orientation

#### 5. Backstitch & Lines

**Given** a user selects the "Backstitch" tool  
**When** they click two cells in sequence  
**Then** a line (backstitch) is drawn between the center of those cells

**Given** a user draws a backstitch  
**When** the pattern is exported  
**Then** the backstitch is rendered as a line overlay on the grid (separate from cross-stitches)

#### 6. Undo/Redo

**Given** a user performs edit operations  
**When** they press Cmd+Z (Mac) or Ctrl+Z (Windows)  
**Then** the last operation is undone

**Given** a user has undone operations  
**When** they press Cmd+Shift+Z (Mac) or Ctrl+Y (Windows)  
**Then** the last undone operation is redone

**Given** a user performs ≥ 50 operations  
**When** they attempt to undo  
**Then** the undo history supports at least 50 actions per PRD

**Given** the undo/redo stack is full  
**When** a new operation is performed  
**Then** the oldest operation in history is dropped (FIFO)

#### 7. Keyboard Shortcuts

**Given** a user is editing a design  
**When** they press keyboard shortcuts  
**Then** the following shortcuts work:
- `U` = Undo
- `R` = Redo
- `Z` = Zoom in
- `X` = Zoom out
- `E` = Eraser tool
- `B` = Backstitch tool
- `H` = Half-stitch tool
- `Q` = Quarter-stitch tool
- `Spacebar` (hold) = Pan mode (drag canvas without editing)

#### 8. Tool Palette

**Given** the editor is open  
**When** the tool palette is displayed  
**Then** the following tools are visible with icons:
- Pencil (full cross-stitch)
- Eraser (remove stitches)
- Backstitch (line drawing)
- Half-stitch (diagonal)
- Quarter-stitch (corner detail)
- Eyedropper (pick colour from existing stitch)

**Given** a user selects a tool  
**When** the tool is active  
**Then** the tool icon is highlighted and the cursor changes to indicate the active tool

---

## User Story 2.2: Colour Palette & Symbols

**(PRD Story #7)**

**As** a user, **I want to** see a curated palette of thread colours (with symbols), and optionally customize symbols or colours, **so that** my charts are clear and reflect my thread stash.

### Priority
**P1** - Inseparable from the editor

### User Personas
- **Emma** (Amateur Hobbyist): Wants a "pretty palette" that matches her physical DMC thread collection
- **Maya** (Small Business Owner): Needs clear symbols for her printable pattern kits sold on Etsy
- **Alex** (Casual Experimenter): Expects modern colour picker (like design tools they've used before)

### Why This Priority
Colours and symbols are the language of cross-stitch. Without a professional palette and symbol management, the app is unusable. The palette is not just a feature—it's the data model foundation for every stitch in the design.

### Independent Test
User opens the colour palette, browses 200+ DMC colours, selects "DMC 310 Black", sees the assigned symbol (e.g., "A"), adds stitches to the canvas, views the auto-generated legend showing "A = DMC 310 Black", and customizes the symbol from "A" to "♠".

---

### Acceptance Criteria (from PRD)

#### 1. Default DMC Palette

**Given** the application is initialized  
**When** a user creates a new design  
**Then** the colour palette includes ≥ 200 DMC thread colours per PRD

**Given** the palette is displayed  
**When** the user browses colours  
**Then** each colour shows:
- DMC number (e.g., "310")
- Colour name (e.g., "Black")
- Colour swatch (visual representation)
- Assigned symbol (e.g., "A", "1", "@")

**Given** the user views the palette  
**When** colours are rendered  
**Then** colours are organized by hue family (reds, blues, greens, etc.) for easy browsing

#### 2. Colour Selection

**Given** a user is editing a design  
**When** they click a colour in the palette  
**Then** that colour becomes the active colour (highlighted)

**Given** a colour is active  
**When** the user adds stitches  
**Then** all new stitches use the active colour

**Given** the user has the eyedropper tool selected  
**When** they click an existing stitch  
**Then** the active colour changes to match that stitch's colour

#### 3. Symbol Assignment (Auto-Generated)

**Given** a design uses multiple colours  
**When** the colour legend is generated  
**Then** each colour is assigned a unique symbol from the pool: A-Z, a-z, 0-9, @, #, *, etc. (≥ 62 unique symbols)

**Given** a design uses ≥ 62 colours  
**When** symbols are exhausted  
**Then** multi-character symbols are used (e.g., "A1", "B2") or patterns (e.g., ▲, ■, ◆)

**Given** a user adds a new colour to the design  
**When** the colour is first used  
**Then** a symbol is automatically assigned and displayed in the legend

#### 4. Symbol Customization

**Given** a user views the colour legend  
**When** they click "Edit Symbol" for a colour  
**Then** a symbol picker dialog opens

**Given** the symbol picker is open  
**When** the user selects a new symbol (e.g., change "A" to "♠")  
**Then** the symbol updates globally (all instances in the legend and grid)

**Given** a user assigns a duplicate symbol (already used by another colour)  
**When** they attempt to save  
**Then** a validation error appears: "This symbol is already used by [Colour Name]"

#### 5. Colour Legend (Auto-Generated)

**Given** a design has ≥ 1 colour in use  
**When** the legend is displayed  
**Then** the legend shows a table with columns:
- Symbol (e.g., "A")
- DMC Number (e.g., "310")
- Colour Name (e.g., "Black")
- Stitch Count (number of stitches using this colour)

**Given** the legend is displayed  
**When** the user makes edits (adds/removes stitches)  
**Then** the legend updates automatically and stitch counts reflect real-time changes

**Given** a colour is no longer used in the design (all stitches removed)  
**When** the legend updates  
**Then** that colour is removed from the legend automatically

#### 6. Colour Palette Management

**Given** a user wants to swap colours  
**When** they select "Replace Colour" in the palette menu  
**Then** a dialog prompts: "Replace [Current Colour] with [New Colour]?"

**Given** the user confirms a colour replacement  
**When** the replacement executes  
**Then** all stitches using the old colour change to the new colour instantly

**Given** a user wants to reduce the colour count  
**When** they select "Simplify Palette" (future: posterization tool)  
**Then** similar colours are merged (v1.1 feature; placeholder for MVP)

#### 7. Palette Persistence

**Given** a user customizes symbols or replaces colours  
**When** the design is saved (autosave or manual)  
**Then** the `symbolMap` and `palette` JSON fields are persisted per SDD Section 9.1

**Given** a user reopens a saved design  
**When** the design loads  
**Then** the palette and symbol assignments are restored exactly as saved

---

## Edge Cases & Considerations

### Canvas Performance
- **Large grids (500×500):** Test rendering performance; may require canvas culling (only render visible stitches)
- **Rapid editing (spam-clicking):** Debounce or throttle stitch additions to prevent lag
- **Undo/redo on large operations:** Bulk colour change for 1000+ stitches must complete in < 1 second

### Colour Palette
- **User deletes a colour in use:** Confirm before deleting; show stitch count impact
- **Colour picker for custom colours (not DMC):** MVP restricted to DMC palette per PRD; custom colours defer to v1.1
- **Colour name localization:** MVP uses English names only; i18n deferred to v1.1

### Fractional Stitches
- **Overlapping fractional stitches:** Two half-stitches in the same cell should form an "X" visually
- **Backstitch over fractional stitches:** Rendering order matters; backstitch should layer on top

### Symbol Conflicts
- **User assigns duplicate symbols:** Validation prevents; suggest next available symbol
- **Symbol exhaustion (> 62 colours):** Use multi-character symbols or warn user to simplify palette

---

## Success Criteria

### Feature 2 Complete When:
- ✅ User can create a blank 100×100 grid and edit stitches
- ✅ Left-click adds stitches; right-click removes
- ✅ Drag-to-select and bulk colour change work
- ✅ Undo/redo supports ≥ 50 actions
- ✅ Palette displays ≥ 200 DMC colours with symbols
- ✅ Auto-generated legend updates in real-time
- ✅ Symbol customization persists across sessions
- ✅ Fractional stitches and backstitches render correctly
- ✅ Canvas maintains 60 FPS at 100×100 grid per Constitution SLO
- ✅ Keyboard shortcuts (U, R, Z, X, E, B, H, Q, Spacebar) functional
- ✅ Integration tests pass for canvas interactions and palette updates

### Performance Targets
- **Canvas render:** 60 FPS at 100×100 grid baseline (Constitution SLO)
- **Stitch addition latency:** < 16 ms (instant feedback)
- **Undo/redo latency:** < 50 ms (imperceptible delay)
- **Legend generation:** < 100 ms (real-time update)
- **Bulk colour change (1000 stitches):** < 500 ms

---

## Technical References

### Constitution Alignment
- **Principle II: Accessibility & Simplicity** - Low cognitive load; intuitive click-to-edit
- **Principle V: Performance-First Design** - Canvas 60 FPS at 100×100 grid (SLO)

### SDD Alignment
- **Section 7.1:** Frontend Key Modules (Canvas Rendering Layer, Design State)
- **Section 7.2:** State Management Strategy (Redux/Context with immutable updates for undo/redo)
- **Section 9.1:** SQL Tables (Designs: `stitchData`, `palette`, `symbolMap` JSON fields)
- **Section 14.2:** Design Grid Serialization (flat array representation for cells)

### PRD Alignment
- **Story #2:** Interactive Pattern Editor (acceptance criteria preserved above)
- **Story #7:** Colour Palette & Symbols (acceptance criteria preserved above)
- **Success Criteria:** Canvas Render 60 FPS, First-Session Success 70%

---

## Dependencies & Blockers

**Depends On:**
- Feature 1: Auth & Persistence (requires design CRUD and autosave for persistence)

**Blocks:**
- Feature 3: Content Generation (photo import/lettering need canvas to display generated content)
- Feature 4: Export (PDF/PNG generation requires completed designs with palette)

**External Dependencies:**
- DMC thread colour library (static JSON file with 200+ colours, names, hex codes)
- Symbol font or Unicode symbols for legend rendering

---

## Follow-up Work (Post-Feature 2)

After Feature 2 completes, the application is a **functional MVP**:
- Users can manually create patterns end-to-end
- Autosave ensures no data loss
- **Demo-ready:** Show to beta users for feedback

**Next Steps:**
- **Feature 3** adds photo import and lettering (enhanced input methods)
- **Feature 4** adds export (complete the create→edit→export workflow)

**Future Enhancements (v1.1+):**
- Custom colour palettes (beyond DMC)
- Layers (separate foreground/background)
- Grid overlay toggle
- Ruler/measurement tools
- Copy/paste regions of stitches
- Pattern templates (hearts, borders, frames)

---

**Status:** Not Started  
**Estimated Effort:** 3-4 weeks (canvas rendering + state management + palette logic)  
**Owners:** Frontend team (canvas UI) + Design team (UX for tool palette and colour picker)
