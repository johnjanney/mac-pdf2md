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
- Defined scope, requirements, recommended architecture, milestones, and the
  Semantic Versioning policy for the project.

> _No application code yet — the project is in the brief/planning phase._

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
