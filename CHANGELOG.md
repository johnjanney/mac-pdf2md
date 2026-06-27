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
