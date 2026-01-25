# Cross Stitch Pattern Design Website – Design Document

Overview

The goal is to build a modern web‑based application that allows users to design cross‑stitch patterns.  Users can import photos or start from a blank canvas, add text in any font, edit colours and stitches and then save their designs for later.  A user account system will allow designs to be persisted in the cloud so they can be revisited, exported or shared.  The system will be deployed on Microsoft Azure using services such as App Service, Azure SQL Database and Blob Storage to provide scalability and reliability.

Cross‑stitch pattern software on the market has several useful capabilities that inform our requirements.  For example, professional tools like Cross Stitch Professional Platinum allow users to convert photos to patterns and to use any fonts installed on their computer ￼.  Apps like StitchSketch include tracing over images and provide dozens of built‑in fonts for lettering ￼.  Free web tools such as FlossCross let users import photos, draw designs on a grid, autosave patterns and export PDFs ￼.  These sources highlight the importance of photo import, multiple fonts, intuitive editing tools, autosave and export functions.

Functional Requirements

Pattern Creation Features
 • Photo import:  Users must be able to upload images (JPEG/PNG).  The system will convert the image into a cross‑stitch grid by resizing it to a specified number of stitches and mapping colours to the nearest thread palette.  Existing software demonstrates that auto‑conversion of photos to cross‑stitch patterns is highly desirable ￼, but often requires manual tweaking for quality.
 • Max upload size:  To manage storage and processing overhead, uploaded images will have a default maximum size of 10 MB.  This limit can be adjusted later based on performance testing and user feedback.
 • Drawing/editing tools:  A graphical editor will allow users to add or remove stitches on a grid, choose colours, draw lines and backstitch, and undo/redo.  The interface should support fractional stitches and provide a palette of thread colours similar to FlossCross ￼.
 • Lettering:  Users can insert text anywhere on the canvas.  The application must render text using any web font (e.g., from Google Fonts) and then convert it into a cross‑stitch grid.  Cross‑stitch software allows use of installed fonts ￼ and even dozens of built‑in fonts ￼; we will support all fonts available via CSS.
 • Colour palette & symbols:  Provide a large library of thread colours and assign symbols to each colour.  Users should be able to change a symbol or colour manually.  Exported charts should include a legend.
 • Export:  Designs can be exported in PDF or PNG formats.  PDF allows high‑quality printing and PNG provides a raster image suitable for sharing.  Other formats may be added later as needed.  FlossCross supports PDF export ￼ and demonstrates the usefulness of portable document formats.
 • Autosave & restore:  Changes should autosave so users do not lose progress.  FlossCross stores patterns locally and restores them automatically ￼.  Our application will store drafts in the database with periodic autosave.

User Accounts & Persistence
 • Authentication:  Users must register and log in.  Instead of requiring Microsoft Entra ID accounts, the site will support third‑party social logins via OAuth 2.0 and OpenID Connect.  Supported providers will include Google, Facebook, Apple ID and Microsoft accounts.  A hosted identity service (for example, Auth0 or Azure AD B2C configured with external identity providers) will manage authentication flows and return a JSON Web Token (JWT) to the front‑end.  The system will store only the provider’s user identifier and minimal profile data.
 • Design storage:  Users can create, edit and delete their designs.  Each design record will contain metadata (title, size, number of colours), the design grid data, and references to uploaded images stored in Blob Storage.  Storing images in Azure Blob Storage is considered best practice for static content and allows scalable storage ￼.
 • User settings:  Allow users to configure default grid sizes, preferred thread palettes and favourite fonts.

Collaboration & Sharing (optional future work)
 • Sharing:  Not included in the initial release.  The ability to share designs via public links or social feeds is considered a future enhancement.
 • Comments/likes:  Not included in the initial release.  Community features such as comments and likes are reserved for later development phases.

Non‑Functional Requirements
 • Scalability:  The application must handle concurrent users by scaling the web server horizontally.  Azure App Service can scale out to multiple instances automatically.
 • Performance:  Generating a cross‑stitch pattern from an image involves computationally expensive image processing.  These tasks will run asynchronously (e.g., in Azure Functions or a background job) so that the UI remains responsive.
 • Availability & reliability:  Deploy across at least two availability zones in production to avoid downtime.  Use Azure SQL Database with zone‑redundant configuration and replicate Blob Storage across regions to protect against data loss.
 • Security:  Use HTTPS for all communications.  Authentication is delegated to a trusted identity provider configured with third‑party social logins; only users with valid tokens can access protected API endpoints.  Secrets (database connection strings, storage keys and identity client secrets) must be stored in Azure Key Vault.
 • Compliance & privacy:  User‑uploaded images and designs are personal data.  Only the owner should be able to view and edit a design unless it is explicitly shared.  In the initial release, designs and uploaded images will be retained indefinitely unless the user deletes them.  Data retention and deletion policies can be refined later to comply with GDPR/CCPA and other regulations.
 • Browser compatibility:  Support modern browsers on desktop and mobile.  Use progressive web app (PWA) techniques to allow offline access and installation.

System Architecture

High‑Level Overview

The application follows a typical client–server architecture with a single‑page application (SPA) front‑end and a set of REST/GraphQL APIs.  The high‑level architecture is shown below:
