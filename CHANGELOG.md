# Changelog

All notable changes to PDF2MD are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## How versioning works in this project

PDF2MD uses **Semantic Versioning**: `MAJOR.MINOR.PATCH`.

- **MAJOR** — incompatible or significant user-facing changes (e.g. dropping
  support for an older macOS version, a redesigned workflow).
- **MINOR** — new, backward-compatible functionality (e.g. adding OCR, a
  recursive-folder toggle).
- **PATCH** — backward-compatible bug fixes and minor improvements.

Rules of thumb:

- During initial development the version stays in the `0.y.z` range; behavior
  may change between minor versions until the first stable release, **`1.0.0`**.
- Pre-releases use suffixes: `-alpha.N`, `-beta.N`, `-rc.N`
  (e.g. `1.0.0-beta.1`).
- Each release is tagged in git as `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`).
- The app's version (`CFBundleShortVersionString`), the latest heading in this
  file, and the git tag must always agree.

### How to update this changelog

1. Add every notable change under the `## [Unreleased]` section as you work,
   grouped under **Added / Changed / Deprecated / Removed / Fixed / Security**.
2. At release time, rename `[Unreleased]` to the new version with the release
   date (`## [1.2.0] - YYYY-MM-DD`), then create a fresh empty `[Unreleased]`
   section above it.
3. Tag the release in git and bump the version in the Xcode target to match.

---

## [Unreleased]

### Added
- **AI (LLM) conversion engine** for high-fidelity Markdown that preserves
  headings, tables, and charts. Each PDF page is rendered to an image and sent
  to a vision model for transcription. Choose between the **Local** engine
  (fast, offline, free) and the **AI** engine in the main window.
  - Providers: **Anthropic (Claude)**, **OpenAI (ChatGPT)**, and
    **Google (Gemini)**, selectable in a new **Settings** window.
  - API keys are stored in the **macOS Keychain**; model IDs are editable per
    provider so the app survives provider model changes.
  - Requires a paid API key and network access; page images are sent to the
    selected provider (clearly noted in the UI). The Local engine remains fully
    offline.
  - Adds the `com.apple.security.network.client` sandbox entitlement (used only
    by the AI engine).

- Output files can now be named after the **document's title** (the first
  on-page heading, falling back to the embedded PDF metadata title) instead of
  the PDF's filename. Controlled by a new "Name files by the document's title"
  option (on by default); falls back to the filename when no title is found.
  Multi-line titles are reassembled by joining adjacent lines of the same
  heading font size. Titles are sanitized and length-capped for safe
  filenames. Unit tests added.
- Initial project documentation: `PROJECTBRIEF.md`, `README.md`,
  `INSTRUCTIONS.md`, `CHANGELOG.md`, and `OPENQUESTIONS.md`.
- Defined scope, requirements, architecture, milestones, and the Semantic
  Versioning policy for the project.
- `LICENSE` — project licensed under the MIT License.
- **Milestone M1 — app scaffolding & skeleton:**
  - Xcode project (`PDF2MD/PDF2MD.xcodeproj`) using synchronized file groups,
    plus an XcodeGen `project.yml` to regenerate it, and `BUILD.md`.
  - SwiftUI app skeleton: single-window UI with PDF/folder selection, output
    folder selection, options, progress, and a per-file results list.
  - `PDFConverter` protocol with a first-party **PDFKit** implementation
    (`PDFKitConverter`) that reconstructs headings, paragraphs, and lists via
    font-size/marker heuristics (baseline; fidelity improves at M4).
  - `BatchEngine` actor for off-main-thread batch conversion with streamed
    progress; one failing file never aborts the batch.
  - `OutputWriter` (numeric-suffix collision policy) and `FileScanner`
    (single files + folders, optional recursion).
  - App Sandbox entitlements scoped to user-selected files.
  - Unit tests for output naming, file scanning, and Markdown assembly.

### Fixed
- File pickers: "Choose PDFs" and "Choose Folder" did nothing because SwiftUI
  only honors one `.fileImporter` per view. Collapsed the three importers into
  a single mode-driven importer.
- "Open Output Folder" / "Reveal" were blocked by the sandbox after a run;
  the app now re-acquires security-scoped access before handing the location
  to Finder.

> _Pre-release (`0.x`): this is an early scaffolding build, not yet
> feature-complete. App version set to `0.1.0`._

---

<!--
Template for future releases — copy this block when cutting a release:

## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Changed
- ...

### Deprecated
- ...

### Removed
- ...

### Fixed
- ...

### Security
- ...
-->
