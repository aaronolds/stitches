# Feature 4: Export & Output

**Priority:** P2 (Output & Completion)  
**Status:** Not Started  
**Dependencies:** Feature 2 (Core Editor)  
**Can Develop in Parallel With:** Feature 3 (Content Generation)

## Overview

This feature enables users to export their completed cross-stitch patterns as high-quality PDF (for printing) or PNG (for digital sharing). Export is the final step in the create→edit→export workflow and represents the deliverable for users to physically produce their designs or share them with others.

**Rationale:**
A pattern is only useful if it can be exported. PDF generation is essential for printing charts for physical stitching, while PNG provides a raster format for social sharing, portfolio display, or digital archiving. This feature completes the user journey and is critical for go-live, but can be developed independently after Feature 2 is stable.

**What this enables:**
- Print-ready PDF with grid, legend, and stitch count
- Digital sharing via high-resolution PNG
- Configurable file naming and format options
- Completion of the full user workflow (create → edit → export → stitch)

---

## User Story 4.1: Export to PDF & PNG

**(PRD Story #6)**

**As** a maker, **I want to** export my pattern as a high-quality PDF (for printing) or PNG (for sharing), **so that** I can produce my design or share it digitally.

### Priority
**P2** - Critical for completion, but development can start after Feature 2 is stable

### User Personas
- **Emma** (Amateur Hobbyist): Wants to print her pattern at home on a standard printer (A4 or Letter size)
- **Maya** (Small Business Owner): Exports professional PDFs for her Etsy shop customers; quality and clarity are non-negotiable
- **Alex** (Casual Experimenter): Wants to share a PNG on Instagram to show friends their cross-stitch design

### Why This Priority
Export is the deliverable for the user's creative work. Without it, patterns are trapped in the app. However, export depends on completed designs (Feature 2), so it's not a blocker for earlier features. This can be developed in parallel with Feature 3 once Feature 2's data model is stable.

### Independent Test
User completes a 50×50 pattern in the editor, clicks "Export", selects "PDF", configures options (paper size: A4, include legend: true, filename: "Holiday Pattern 2026"), downloads the PDF, opens it in a PDF viewer, sees the grid with symbols, legend with DMC colours and stitch counts, and prints successfully on a home printer.

---

### Acceptance Criteria (from PRD)

#### 1. Export Dialog

**Given** a user has a design open  
**When** they click the "Export" button  
**Then** an export dialog appears with options:
- Format: PDF or PNG
- Paper size (PDF only): A4, Letter, 8×10"
- Resolution (PNG only): 300 DPI (default), 150 DPI, 600 DPI
- Include legend: Yes (default) or No
- Filename: Configurable (default: `{design_title}_{timestamp}`)

**Given** the export dialog is open  
**When** the user selects "PDF"  
**Then** paper size options are visible

**Given** the export dialog is open  
**When** the user selects "PNG"  
**Then** resolution options are visible (DPI)

#### 2. PDF Export (Server-Side Generation)

**Given** a user clicks "Export as PDF"  
**When** the API receives the request  
**Then** the backend generates a PDF per SDD Section 14.4

**Given** the PDF is being generated  
**When** the backend processes the design  
**Then** the PDF includes:
- **Pattern grid:** Full cross-stitch grid with symbols in each stitch cell
- **Colour legend:** Table with columns: Symbol | DMC Number | Colour Name | Stitch Count
- **Metadata:** Design title, dimensions (width × height stitches), total stitch count
- **Optional:** Grid lines for easier reading; page numbers if multi-page

**Given** the PDF is generated  
**When** the file is ready  
**Then** the PDF is optimized for printing at common sizes (A4, Letter, 8×10")

**Given** a small pattern (≤ 100×100 stitches)  
**When** the PDF export is triggered  
**Then** generation completes synchronously and the file is streamed to the user per SDD Section 14.4

**Given** a large pattern (> 100×100 stitches)  
**When** the PDF export is triggered  
**Then** generation runs as an async job; user polls for completion (similar to photo conversion workflow)

#### 3. PNG Export (Server-Side Generation)

**Given** a user clicks "Export as PNG"  
**When** the API receives the request  
**Then** the backend renders the pattern as a raster image

**Given** the PNG is being generated  
**When** the backend processes the design  
**Then** the PNG includes:
- **Pattern grid:** Full cross-stitch grid with colour-filled cells (no symbols required; visual representation)
- **Background:** White (default) or transparent (user option)
- **Legend (optional):** Overlay or separate PNG with legend (user choice)

**Given** the PNG resolution is set to 300 DPI  
**When** the PNG is generated  
**Then** the output is high-resolution (minimum 300 DPI per PRD) suitable for digital printing

**Given** the PNG resolution is set to 150 DPI  
**When** the PNG is generated  
**Then** the output is lower-resolution for web sharing (smaller file size)

#### 4. Export Performance

**Given** a user triggers an export  
**When** the backend processes the request  
**Then** export completes within 5 seconds per PRD success criteria

**Given** a small pattern (≤ 100×100 stitches) export  
**When** processed  
**Then** generation completes in < 2 seconds (synchronous)

**Given** a large pattern (> 200×200 stitches) export  
**When** processed  
**Then** generation runs asynchronously; status polling updates every 2 seconds

#### 5. File Naming & Download

**Given** the export completes  
**When** the file is ready  
**Then** the filename follows the pattern: `{design_title}_{timestamp}.{pdf|png}`

**Given** the user configured a custom filename in the export dialog  
**When** the file is generated  
**Then** the custom name is used (with illegal characters sanitized, e.g., replace `/` with `-`)

**Given** the file is ready for download  
**When** the user clicks "Download"  
**Then** the browser downloads the file to the default downloads folder

**Given** the file is downloaded  
**When** the user opens it  
**Then** the file renders correctly in PDF viewers (Acrobat, Preview) or image viewers (Photos, browser)

#### 6. Legend Inclusion

**Given** the user selects "Include legend: Yes"  
**When** the PDF is generated  
**Then** the legend appears on the first page or last page with:
- Symbol column (visual representation of each symbol)
- DMC Number column (e.g., "310")
- Colour Name column (e.g., "Black")
- Stitch Count column (number of stitches for this colour)
- Total stitch count footer (sum of all stitches)

**Given** the user selects "Include legend: No"  
**When** the PDF is generated  
**Then** only the pattern grid is rendered (no legend table)

**Given** the user exports a PNG with "Include legend: Yes"  
**When** the PNG is generated  
**Then** the legend is overlaid on the bottom or right side of the image, or provided as a separate PNG file

#### 7. Multi-Page PDF (Large Patterns)

**Given** a pattern exceeds the printable area for a single page (e.g., 300×300 stitches on A4)  
**When** the PDF is generated  
**Then** the pattern is split across multiple pages with:
- Page numbers (e.g., "Page 1 of 4")
- Grid alignment marks (e.g., "Continue to Page 2 at row 100")
- Legend on the first page

**Given** a multi-page PDF is generated  
**When** the user prints it  
**Then** pages can be reassembled to form the complete pattern (tiled printing)

#### 8. Error Handling

**Given** an export job fails (e.g., PDF generation crashes, out of memory)  
**When** the failure is detected  
**Then** the UI displays: "Export failed. Please try again or contact support."

**Given** a user triggers multiple exports simultaneously  
**When** the second export is triggered  
**Then** the first export is cancelled or queued (prevent concurrent exports per user)

---

## Edge Cases & Considerations

### PDF Generation
- **Large patterns (500×500):** May require multi-page tiling; test pagination logic carefully
- **Special characters in filename:** Sanitize filenames to prevent filesystem errors (e.g., replace `/` with `-`)
- **PDF size limits:** If pattern exceeds 100 pages, warn user or truncate (future: vector PDF for infinite zoom)
- **Colour accuracy:** Ensure DMC colour hex codes render accurately in PDF (test on different PDF viewers)

### PNG Generation
- **Memory usage:** Rendering 500×500 patterns at 600 DPI may consume significant RAM; test memory limits
- **Transparent backgrounds:** PNG with transparency is useful for overlays; test alpha channel rendering
- **Legend overlay positioning:** Ensure legend doesn't obscure the pattern; provide positioning options (bottom, right, separate file)

### Export Performance
- **Concurrent exports:** Limit to 1 concurrent export per user to prevent resource exhaustion
- **Export retries:** If job fails, allow user to retry up to 3 times before escalating to support
- **Caching:** Consider caching exports for 24 hours (if design unchanged, reuse cached PDF/PNG to reduce compute)

### Printing Considerations
- **Printer margins:** Ensure grid doesn't get clipped by printer margins (test on multiple printers)
- **Black-and-white printing:** If user prints on B&W printer, symbols must be distinct (test symbol clarity)
- **Large format printing:** For professional users (Maya), future: support poster sizes (18×24", 24×36")

---

## Success Criteria

### Feature 4 Complete When:
- ✅ User can export a design as PDF with grid, legend, and metadata
- ✅ User can export a design as PNG at 300 DPI minimum
- ✅ PDF is optimized for printing on A4, Letter, and 8×10" paper
- ✅ PNG has white background (default) and optional transparent background
- ✅ Export completes within 5 seconds per PRD (p95)
- ✅ File naming is configurable and follows `{design_title}_{timestamp}.{ext}` pattern
- ✅ Multi-page PDF works correctly for large patterns (> 200×200 stitches)
- ✅ Legend inclusion is optional and renders correctly in PDF and PNG
- ✅ Integration tests pass for PDF and PNG generation with various pattern sizes

### Performance Targets
- **Small patterns (≤ 100×100):** Export < 2 seconds (synchronous)
- **Large patterns (100-200 stitches):** Export < 5 seconds (p95) per PRD
- **Very large patterns (> 200×200):** Async job < 10 seconds (p95)
- **File size:** PDF < 5 MB for typical 100×100 pattern; PNG < 10 MB at 300 DPI

---

## Technical References

### Constitution Alignment
- **Principle V: Performance-First Design** - Export < 5 seconds (p95)

### SDD Alignment
- **Section 8.5:** Export (PDF/PNG) - Small patterns synchronous, large patterns async
- **Section 9.2:** Blob Storage Layout - Optional export caching: `{userId}/{designId}/exports/{timestamp}.{pdf|png}`
- **Section 14.4:** MVP Decision - Server-side generation for consistent fidelity

### PRD Alignment
- **Story #6:** Export to PDF & PNG (acceptance criteria preserved above)
- **Success Criteria:** Export < 5 seconds (p95), print-optimized formats

---

## Dependencies & Blockers

**Depends On:**
- Feature 2: Core Editor (requires completed designs with `stitchData`, `palette`, `symbolMap`)

**Can Develop in Parallel With:**
- Feature 3: Content Generation (photo import and export are independent workflows)

**External Dependencies:**
- PDF generation library (backend): Per SDD Section 15, specific library TBD; candidates: PdfSharp (.NET), ReportLab (Python), PDFKit (Node.js)
- PNG generation library (backend): Per SDD Section 15, specific library TBD; candidates: ImageSharp (.NET), Pillow (Python), Sharp (Node.js)
- Azure Blob Storage (optional: for export caching)

---

## Follow-up Work (Post-Feature 4)

After Feature 4 completes:
- **Full workflow operational:** Users can create → edit → export → stitch
- **MVP is complete:** All 7 PRD user stories (+ 3 infrastructure stories) delivered
- **Beta testing:** Validate export quality with real users printing on various printers

**Future Enhancements (v1.1+):**
- Export to other formats: SVG (vector), XSD (cross-stitch data format)
- Export customization: Colour vs. black-and-white, symbol size, grid thickness
- Batch export: Export multiple designs in one ZIP file
- Print directly from browser (browser print dialog integration)
- Export to cross-stitch machine formats (e.g., Brother, Janome)

**SDD Section 15 Open Items (Resolved Post-Feature 4):**
- Select specific PDF generation library after licensing review and performance testing
- Select specific PNG generation library after canvas rendering benchmarks

---

**Status:** Not Started  
**Estimated Effort:** 2-3 weeks (PDF/PNG generation + async job logic + multi-page tiling)  
**Owners:** Backend team (PDF/PNG libraries, rendering logic) + Frontend team (export dialog UI, file download)
