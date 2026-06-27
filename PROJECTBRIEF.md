# Project Brief: PDF2MD for macOS

> **Status:** Draft — for review before implementation begins
> **Last updated:** 2026-06-27
> **Owner:** johnjanney
> **Target platform:** macOS (Apple Silicon, optimized for MacBook Air)

---

## 1. Purpose

PDF2MD is a native macOS desktop application that converts PDF files into
Markdown (`.md`) files. It is designed for a single user working locally on a
MacBook Air who needs a fast, private, offline way to turn documents into clean,
editable Markdown.

The app must support:

- **Single-file conversion** — pick one PDF, convert it to one `.md` file.
- **Batch conversion** — pick many PDFs (or a folder of PDFs) and convert them
  all in one run.
- **User-selected output folder** — the user chooses where converted `.md`
  files are written.

This document is the source of truth for *what* we are building and *how* it is
scaffolded. It is written so that Claude Code (or any developer) can pick it up
and begin implementation without further clarification on scope. Genuinely
undecided items live in [`OPENQUESTIONS.md`](./OPENQUESTIONS.md).

---

## 2. Goals and Non-Goals

### 2.1 Goals (v1.0)

1. Convert a single PDF to Markdown via a native macOS GUI.
2. Convert a batch of PDFs (multi-select or whole-folder) to Markdown.
3. Let the user pick the output folder before conversion.
4. Preserve document structure as faithfully as practical: headings,
   paragraphs, lists, tables, and basic inline formatting (bold/italic).
5. Run **fully offline** — no document data leaves the machine.
6. Provide clear progress feedback and a per-file success/failure summary.
7. Ship as a normal macOS `.app` the user can run from `/Applications`.

### 2.2 Non-Goals (v1.0)

- Windows or Linux support.
- OCR of scanned/image-only PDFs (tracked as a future enhancement — see
  [`OPENQUESTIONS.md`](./OPENQUESTIONS.md)).
- Editing Markdown inside the app (it is a converter, not an editor).
- Cloud sync, accounts, or any network features.
- Converting formats other than PDF → Markdown.
- App Store distribution in v1.0 (revisit later).

---

## 3. Target User and Environment

- **User:** Single technical/semi-technical user.
- **Hardware:** MacBook Air (Apple Silicon — M1 or newer assumed).
- **OS:** macOS 14 (Sonoma) or later. (Confirm minimum target — see Open
  Questions.)
- **Usage pattern:** Occasional to frequent local conversions; values speed,
  privacy, and a clean native feel over configurability.

---

## 4. Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-1 | User can select a single PDF file via a native file picker. | Must |
| FR-2 | User can select multiple PDF files at once. | Must |
| FR-3 | User can select an entire folder; the app finds all PDFs within it. | Must |
| FR-4 | User can choose the output folder via a native folder picker. | Must |
| FR-5 | Each input `name.pdf` produces `name.md` in the output folder. | Must |
| FR-6 | App shows progress (current file, count, % or N of M). | Must |
| FR-7 | App shows a per-file result summary (succeeded / failed + reason). | Must |
| FR-8 | App handles filename collisions safely (no silent overwrite). | Must |
| FR-9 | Converted Markdown preserves headings, paragraphs, lists. | Must |
| FR-10 | Converted Markdown preserves tables where detectable. | Should |
| FR-11 | App preserves bold/italic inline emphasis where detectable. | Should |
| FR-12 | App handles a single corrupt/unreadable PDF without aborting the batch. | Must |
| FR-13 | Recursive folder scan is optional (toggle subfolders on/off). | Could |
| FR-14 | User can open the output folder in Finder after a run. | Could |

### 4.1 Output naming and collision rules

- Default: `document.pdf` → `document.md` in the chosen output folder.
- If `document.md` already exists, the app must **not** silently overwrite.
  Default behavior: append a numeric suffix (`document-1.md`, `document-2.md`).
  An "Overwrite existing" option may be offered. (Confirm default — see Open
  Questions.)
- When batch input contains two PDFs that map to the same output name (e.g.
  same name from different folders), apply the same suffix rule.

---

## 5. Non-Functional Requirements

- **Privacy:** 100% local processing. No telemetry, no network calls in v1.0.
- **Performance:** A typical 10-page text PDF should convert in a few seconds on
  M-series hardware. Batch runs should not block the UI (conversion runs off the
  main thread).
- **Reliability:** One bad file never crashes the app or aborts a batch.
- **Footprint:** Reasonable app bundle size for a laptop; no heavyweight
  background services.
- **Accessibility:** Respect system Light/Dark mode and Dynamic Type where
  feasible.

---

## 6. Recommended Technical Approach

> The conversion *engine* is the most consequential technical decision. A
> recommendation is made below; alternatives and the final call are tracked in
> [`OPENQUESTIONS.md`](./OPENQUESTIONS.md).

### 6.1 UI layer — **SwiftUI (native macOS app)**

- **Language:** Swift 5.9+
- **UI framework:** SwiftUI, targeting macOS 14+.
- **Why:** Native look and feel, smallest footprint, best fit for a MacBook Air,
  no runtime to bundle for the UI, easy access to native file/folder pickers
  (`NSOpenPanel` / `.fileImporter`) and Finder integration.

### 6.2 Conversion engine — two candidate strategies

**Option A (recommended for fidelity): bundle a Python conversion engine.**

- Use a mature Python library such as **`pymupdf4llm`** (PyMuPDF-based,
  Markdown-oriented, good structure/table handling) invoked as a helper.
- The Swift app ships an embedded Python runtime or a self-contained helper
  binary (e.g. built with PyInstaller) and calls it as a subprocess.
- **Pro:** Best Markdown fidelity (headings, tables, lists) with low effort.
- **Con:** Larger bundle; must verify the library's license is compatible with
  distribution (PyMuPDF is AGPL — **this must be checked**, see Open Questions).

**Option B (recommended for a pure-native, license-clean build): Swift + PDFKit.**

- Use Apple's **PDFKit** to extract text and layout, then apply heuristics to
  reconstruct Markdown structure (headings via font-size clustering, lists via
  bullet/indent detection, etc.).
- **Pro:** Single language, no bundled runtime, smallest footprint, clean
  licensing.
- **Con:** More conversion logic to write; table fidelity is weaker.

**Decision needed before coding the engine.** The UI, file handling, batching,
and output logic are identical regardless of engine choice, so UI scaffolding
can proceed in parallel. Define a `PDFConverter` protocol/interface so the
engine is swappable.

### 6.3 Suggested architecture

```
PDF2MD.app
├── App entry (SwiftUI App)
├── UI
│   ├── ConversionView        // file/folder selection, output folder, Convert button
│   ├── ProgressView          // live progress for the active run
│   └── ResultsView           // per-file success/failure summary
├── Core
│   ├── PDFConverter (protocol)        // convert(input:) -> Markdown
│   ├── EngineXConverter (impl)        // PDFKit-based OR Python-helper-based
│   ├── BatchRunner                    // queues files, runs off main thread
│   ├── OutputWriter                   // naming, collision handling, writing .md
│   └── FileScanner                    // expand folders -> [PDF URLs]
└── Resources
    └── (bundled helper binary, if Option A)
```

### 6.4 Key implementation notes

- Run conversions on a background queue/Task; keep the UI responsive and
  cancellable.
- Use security-scoped resource access for user-selected files/folders (required
  under macOS sandboxing if the app is sandboxed).
- Stream progress updates back to the UI on the main actor.
- Treat the converter as fallible per file; collect results, never crash a run.

---

## 7. Project Scaffolding

Recommended initial repository layout:

```
mac-pdf2md/
├── README.md               # GitHub front page / overview
├── PROJECTBRIEF.md         # this file
├── INSTRUCTIONS.md         # how to use the app
├── CHANGELOG.md            # log of changes + versioning policy
├── OPENQUESTIONS.md        # unresolved decisions
├── LICENSE                 # to be added (see Open Questions)
├── .gitignore              # Xcode/Swift/macOS ignores
└── PDF2MD/                 # Xcode project (created at implementation time)
    ├── PDF2MD.xcodeproj
    ├── PDF2MD/             # Swift sources (UI + Core as above)
    ├── PDF2MDTests/        # unit tests (converter, naming, scanner)
    └── Resources/
```

> Only the documentation files are created in this brief stage. The Xcode
> project and Swift sources are produced in the implementation phase.

### 7.1 Tooling and conventions

- **Build:** Xcode (latest stable) + Swift Package Manager for dependencies.
- **Formatting/linting:** SwiftFormat and/or SwiftLint (configure in
  implementation phase).
- **Tests:** XCTest for core logic — converter output, naming/collision rules,
  folder scanning, and batch error isolation.
- **CI (optional, later):** GitHub Actions running `xcodebuild test` on macOS
  runners.

---

## 8. Milestones

| Milestone | Description |
|-----------|-------------|
| M0 — Brief | This document + supporting docs (current step). |
| M1 — Scaffolding | Xcode project, app skeleton, `PDFConverter` protocol, file pickers. |
| M2 — Single-file | End-to-end single PDF → MD with output-folder selection. |
| M3 — Batch | Multi-file/folder selection, background batch runner, progress + results. |
| M4 — Fidelity | Improve headings/lists/tables; collision handling polish. |
| M5 — Packaging | Build, sign/notarize (if applicable), produce distributable `.app`. |
| v1.0 | All Must requirements met; documented and packaged. |

---

## 9. Versioning Policy (Semantic Versioning)

This project follows **[Semantic Versioning 2.0.0](https://semver.org/)**:
`MAJOR.MINOR.PATCH`.

- **MAJOR** — incompatible or significant user-facing changes (e.g. a redesigned
  workflow, dropping support for an older macOS version).
- **MINOR** — new functionality added in a backward-compatible way (e.g. adding
  OCR support, a recursive-scan toggle).
- **PATCH** — backward-compatible bug fixes and small improvements.

Conventions:

- **Pre-1.0 (`0.y.z`):** the app is considered in active initial development;
  the public behavior may change between minor versions. First public,
  feature-complete release is **`1.0.0`**.
- **Pre-release tags:** use `-alpha.N`, `-beta.N`, `-rc.N` (e.g. `1.0.0-beta.1`).
- **Git tags:** tag every release as `vMAJOR.MINOR.PATCH` (e.g. `v1.0.0`).
- **Source of truth:** the version is set in the Xcode target
  (Marketing Version / `CFBundleShortVersionString`) and must match the latest
  entry in [`CHANGELOG.md`](./CHANGELOG.md) and the git tag.
- **Changelog discipline:** every release updates `CHANGELOG.md` following the
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Unreleased
  work accumulates under an `## [Unreleased]` heading and is moved under a
  dated, versioned heading at release time.

---

## 10. Risks and Open Items

The primary open decisions (conversion engine choice, library licensing, minimum
macOS version, sandboxing/notarization, OCR scope, and overwrite defaults) are
tracked in [`OPENQUESTIONS.md`](./OPENQUESTIONS.md) and must be resolved at or
before the relevant milestone.
