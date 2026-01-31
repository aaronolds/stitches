# Feature 3: Content Generation (Import & Lettering)

**Priority:** P2 (Enhanced Input Methods)  
**Status:** Not Started  
**Dependencies:** Feature 2 (Core Editor)  
**Can Develop in Parallel With:** Feature 4 (Export)

## Overview

This feature provides two powerful input methods for creating cross-stitch patterns beyond manual editing: photo-to-pattern auto-conversion and text-to-stitches rendering. Both capabilities leverage async processing to keep the UI responsive and populate the canvas with editable content.

**Rationale:**
Manual stitch-by-stitch editing is powerful but time-consuming. Photo import addresses Emma's use case ("transform holiday photos into quick cross-stitch gifts") and is the #1 requested feature in the market. Lettering enables personalization (names, dates, messages), which is critical for Maya's small business. Both features share similar patterns (async processing, rasterization, canvas placement) and can be developed by the same backend team.

**What this enables:**
- Quick pattern creation from personal photos/memories
- Automatic DMC colour mapping for realistic photo conversion
- Text personalization using Google Fonts
- Editable auto-generated content (users can refine stitch-by-stitch)
- 10x faster pattern creation compared to manual editing

---

## User Story 3.1: Photo Import & Auto-Conversion

**(PRD Story #1)**

**As** a hobbyist, **I want to** upload a JPEG/PNG photo and have it automatically converted to a cross-stitch grid, **so that** I can quickly turn a memory into a pattern.

### Priority
**P2** - High value, but users can manually edit without this

### User Personas
- **Emma** (Amateur Hobbyist): Wants to convert holiday photos (family, pets, sunsets) into cross-stitch gifts
- **Maya** (Small Business Owner): Needs to bulk-convert images for her Etsy shop; quality matters but speed is critical
- **Alex** (Casual Experimenter): Curious about seeing photos as cross-stitch; will abandon if conversion quality is poor

### Why This Priority
Photo conversion is a differentiator vs. desktop tools but not strictly required for MVP value. Users can manually create patterns (Feature 2) or import photos later. However, per the PRD success criteria, "Photo conversion accuracy ≥ 4/5 user satisfaction" is mandatory before launch, making this critical for go-live approval.

### Independent Test
User clicks "Import Photo", uploads a 2MB JPEG of a sunset, selects 100×100 stitch count, sees a progress bar for < 10 seconds, canvas populates with a recognizable cross-stitch version of the sunset (warm colours preserved), and user can refine individual stitches.

---

### Acceptance Criteria (from PRD)

#### 1. Photo Upload

**Given** a user is authenticated  
**When** they click "Import Photo" button  
**Then** a file picker dialog opens accepting JPEG and PNG formats

**Given** a user selects a valid image file  
**When** the file is ≤ 10 MB  
**Then** the upload proceeds to the API

**Given** a user selects an image file  
**When** the file is > 10 MB  
**Then** an error message displays: "File too large. Maximum 10 MB."

**Given** a user uploads a file  
**When** the upload completes  
**Then** the image is stored in Azure Blob Storage per SDD Section 9.2

#### 2. Conversion Settings

**Given** a user's image is uploaded  
**When** the conversion dialog appears  
**Then** the user can configure:
- Target stitch count (width × height, default 100×100)
- Aspect ratio (locked or custom)
- Colour palette (DMC standard or limited palette e.g., 10 colours)
- Posterization level (number of colours to use, e.g., 5, 10, 20, unlimited)

**Given** the user sets a large stitch count (e.g., 500×500)  
**When** they click "Convert"  
**Then** a warning appears: "Large designs may take longer to process and edit."

#### 3. Async Conversion Job

**Given** a user clicks "Convert" after configuring settings  
**When** the API receives the request  
**Then** a conversion job is enqueued per SDD Section 8.4

**Given** the conversion job is enqueued  
**When** the job starts processing  
**Then** the UI displays a progress bar with status: "Converting photo..."

**Given** the conversion is in progress  
**When** the user's session is still active  
**Then** the SPA polls `GET /api/jobs/{jobId}` every 2 seconds for status updates

**Given** the conversion job completes  
**When** the SPA receives `status: Succeeded`  
**Then** the canvas is populated with the converted stitch grid

#### 4. Conversion Quality & Performance

**Given** a photo is being converted  
**When** the backend processes the image  
**Then** the following algorithm is applied (per SDD Section 8.4):
1. Resize image to target stitch count (width × height)
2. For each pixel, map RGB value to nearest DMC thread colour
3. Optionally apply posterization (reduce colour count)
4. Generate `stitchData` JSON with cell array (palette index per cell)
5. Return `designId` with populated grid

**Given** a photo conversion is triggered  
**When** the job executes  
**Then** conversion completes in < 10 seconds (p95) per PRD

**Given** a converted pattern is displayed  
**When** users review the result  
**Then** user satisfaction is ≥ 4/5 (measurable via post-conversion survey or beta feedback)

#### 5. Editable Conversion Result

**Given** a photo conversion completes  
**When** the canvas is populated  
**Then** all stitches are editable (user can change colours, add/remove stitches)

**Given** the converted design is displayed  
**When** the user views the colour legend  
**Then** the legend shows all DMC colours used in the conversion with stitch counts

**Given** the user refines the auto-converted pattern  
**When** they make edits  
**Then** autosave triggers every 30 seconds (Feature 1 autosave logic applies)

#### 6. Error Handling

**Given** a conversion job fails (e.g., invalid image format, processing timeout)  
**When** the failure is detected  
**Then** the UI displays an error message: "Photo conversion failed. Please try again or contact support."

**Given** a conversion job fails after retries  
**When** the failure is logged  
**Then** the job is moved to a poison queue (dead-letter queue) per SDD Section 14.3

**Given** a user's conversion fails  
**When** they retry the upload  
**Then** the previous failed job is discarded and a new job is created

---

## User Story 3.2: Lettering (Text to Stitches)

**(PRD Story #3)**

**As** a user, **I want to** add text anywhere on my canvas in any web font (e.g., Google Fonts), **so that** I can personalize designs with names, dates, or messages.

### Priority
**P2** - High value for personalization

### User Personas
- **Emma** (Amateur Hobbyist): Wants to add "Merry Christmas 2026" to a holiday pattern
- **Maya** (Small Business Owner): Adds customer names to custom patterns (e.g., "Baby Emma" on a baby blanket design)
- **Alex** (Casual Experimenter): Wants to see their name in cross-stitch (experimenting with font styles)

### Why This Priority
Lettering is a key differentiator for personalization. While not strictly required for MVP value (users can manually stitch letters), it dramatically enhances usability for gift-making and custom orders. Feature 2 provides the canvas foundation; lettering is an enhancement.

### Independent Test
User clicks "Add Text", types "Hello World", selects "Pacifico" font from Google Fonts, sets font size to 24, places the text box on the canvas, sees the text rasterized into cross-stitch grid cells, edits individual stitch colours, and saves the design.

---

### Acceptance Criteria (from PRD)

#### 1. Text Insertion

**Given** a user is editing a design  
**When** they click "Add Text" button  
**Then** a text input dialog appears

**Given** the text dialog is open  
**When** the user types text (e.g., "Love You")  
**Then** the preview updates in real-time showing the text in the selected font

**Given** the user confirms text input  
**When** they click "Place on Canvas"  
**Then** a draggable text box appears on the canvas

#### 2. Font Selection

**Given** the text dialog is open  
**When** the user clicks the font dropdown  
**Then** ≥ 50 Google Fonts are available per PRD

**Given** the user selects a font (e.g., "Roboto", "Pacifico", "Lobster")  
**When** the selection is made  
**Then** the preview updates to show the text in the selected font

**Given** the font library is loaded  
**When** the user searches for a font by name  
**Then** autocomplete suggestions help them find fonts quickly

#### 3. Font Size & Rotation

**Given** the text dialog is open  
**When** the user adjusts the font size slider (range: 12-72)  
**Then** the preview updates to show the scaled text

**Given** the text box is placed on the canvas  
**When** the user rotates the text (0°, 90°, 180°, 270°)  
**Then** the text box rotates and the preview updates

**Given** the user sets a large font size (e.g., 72)  
**When** the text is rasterized  
**Then** the stitch count increases proportionally (may exceed canvas size; warn user)

#### 4. Text Rasterization (Server-Side)

**Given** the user places a text box on the canvas  
**When** they click "Rasterize"  
**Then** the API receives: `{ text, fontFamily, fontSize, rotation, position }`

**Given** the API receives a rasterization request  
**When** the backend processes the text  
**Then** the text is rendered to a bitmap image using the specified font

**Given** the bitmap is generated  
**When** the backend maps pixels to stitches  
**Then** black/dark pixels become stitches (monochrome by default); white/transparent pixels remain empty

**Given** the rasterization completes  
**When** the canvas is updated  
**Then** the text appears as stitches in the design grid (editable like any other stitches)

#### 5. Rasterized Text Editing

**Given** text is rasterized to stitches  
**When** the user views the canvas  
**Then** the text stitches are editable (colour changes, add/remove)

**Given** text is rasterized  
**When** the user wants to edit the text content  
**Then** they must delete the rasterized stitches and create a new text layer (text is "baked in" once rasterized)

**Given** text is rasterized  
**When** the user applies a colour  
**Then** all text stitches can be bulk-coloured using drag-to-select (Feature 2 tools apply)

#### 6. Text Layer Management (Pre-Rasterization)

**Given** a user places a text box (not yet rasterized)  
**When** the text box is in "edit mode"  
**Then** the user can:
- Drag the text box to reposition
- Edit the text content
- Change font, size, rotation
- Delete the text box without rasterizing

**Given** the user has multiple text boxes  
**When** they view the layers panel  
**Then** each text box is listed as a separate layer (e.g., "Text: Love You")

**Given** the user deletes a text box  
**When** the deletion is confirmed  
**Then** the text box is removed without affecting rasterized content

---

## Edge Cases & Considerations

### Photo Import
- **Corrupted image files:** Validate file headers; reject with user-friendly error
- **Non-photographic images (line art, logos):** May convert poorly; future: detect and suggest manual tracing
- **Aspect ratio distortion:** Lock aspect ratio by default; allow custom only with explicit user choice
- **Colour count explosion (500+ colours):** Warn user; suggest posterization to reduce palette size
- **Large file uploads (8-10 MB):** Show progress bar; implement chunked upload if needed

### Photo Conversion Quality
- **Low-contrast photos (e.g., foggy scenes):** May result in muddy patterns; future: pre-processing (contrast adjustment)
- **Faces and portraits:** Difficult to convert well at low stitch counts; recommend 200×200 minimum
- **Dark photos:** Conversion may use too many blacks/browns; future: brightness adjustment slider

### Lettering
- **Unicode/Emoji in text:** May not render in all fonts; warn user or filter unsupported characters
- **Very long text (100+ characters):** May exceed canvas size; truncate or suggest breaking into multiple text boxes
- **Font loading failures:** Fallback to system font (e.g., Arial) if Google Font fails to load
- **Text overlaps existing stitches:** Rasterization overwrites existing content; warn user before rasterizing

### Performance
- **Large photo conversions (500×500):** May exceed 10-second SLO; consider time limit or abort if > 30 seconds
- **Concurrent conversion jobs:** Limit to 5 concurrent jobs per user to prevent resource exhaustion
- **Text rasterization for large fonts (72pt):** May generate 500+ stitches; ensure < 5-second rasterization

---

## Success Criteria

### Feature 3 Complete When:
- ✅ User can upload JPEG/PNG (≤ 10 MB) and convert to cross-stitch pattern
- ✅ Photo conversion completes in < 10 seconds (p95) per PRD
- ✅ Converted patterns are editable (user can refine stitches)
- ✅ User satisfaction ≥ 4/5 on photo conversion quality (beta feedback)
- ✅ User can add text with ≥ 50 Google Fonts
- ✅ Text rasterizes to stitches and is editable
- ✅ Font size and rotation adjustments work correctly
- ✅ Async job polling UI displays progress and handles errors gracefully
- ✅ Integration tests pass for photo upload and text rasterization

### Performance Targets
- **Photo conversion:** < 10 seconds (p95) per PRD
- **Text rasterization:** < 5 seconds (p95)
- **Blob upload:** < 5 seconds for 10 MB file
- **Job polling:** 2-second intervals; status updates appear < 5 seconds after completion

---

## Technical References

### Constitution Alignment
- **Principle I: Cloud-First Architecture** - Uploaded images stored in Azure Blob Storage
- **Principle III: User-Centric Quality** - Photo conversion ≥ 4/5 satisfaction before launch
- **Principle V: Performance-First Design** - Photo conversion < 10 seconds (p95)

### SDD Alignment
- **Section 8.4:** Image Upload & Conversion (Async workflow, Blob Storage, job queues)
- **Section 9.2:** Blob Storage Layout (`{userId}/{designId}/original.{ext}`)
- **Section 14.3:** Background Jobs (Azure Storage Queues, retries, poison queue)

### PRD Alignment
- **Story #1:** Photo Import & Auto-Conversion (acceptance criteria preserved above)
- **Story #3:** Lettering (Text to Stitches) (acceptance criteria preserved above)
- **Success Criteria:** Photo conversion ≥ 4/5 satisfaction, < 10 seconds (p95)

---

## Dependencies & Blockers

**Depends On:**
- Feature 2: Core Editor (requires canvas to display converted content)

**Can Develop in Parallel With:**
- Feature 4: Export (photo import and export are independent workflows)

**External Dependencies:**
- Azure Blob Storage for uploaded images
- Azure Storage Queues (or Functions) for async job processing per SDD Section 14.3
- Google Fonts API for font library (static list; no real-time API calls per PRD Section 3)
- Image processing library (backend): e.g., ImageSharp (.NET), Pillow (Python), Sharp (Node.js)

---

## Follow-up Work (Post-Feature 3)

After Feature 3 completes:
- Users can create patterns via 3 methods: manual (Feature 2), photo import, or lettering
- Photo conversion workflow: upload → job status → editable result → autosave
- Lettering workflow: add text → rasterize → edit stitches → autosave

**Future Enhancements (v1.1+):**
- Pre-processing controls: brightness, contrast, posterization preview
- Multiple text layers (keep layers editable until explicitly rasterized)
- Custom colour palettes (beyond DMC) for conversion
- Batch photo upload (convert multiple photos in one session)
- AI-powered conversion quality improvements (edge detection, dithering)

---

**Status:** Not Started  
**Estimated Effort:** 3-4 weeks (async job infrastructure + image processing + font rendering)  
**Owners:** Backend team (image processing, job queues) + Frontend team (upload UI, job polling, text placement)
