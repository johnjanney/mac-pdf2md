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
5. Run **fully offline by default** (the local PDFKit engine) — no document
   data leaves the machine. An **opt-in AI engine** trades this for higher
   fidelity (see §6.5).
6. Provide clear progress feedback and a per-file success/failure summary.
7. Ship as a normal macOS `.app` the user can run from `/Applications`.

### 2.2 Non-Goals (v1.0)

- Windows or Linux support.
- OCR of scanned/image-only PDFs (tracked as a future enhancement — see
  [`OPENQUESTIONS.md`](./OPENQUESTIONS.md)).
- Editing Markdown inside the app (it is a converter, not an editor).
- Cloud sync or accounts. (Note: the optional AI engine added in `0.x` makes
  outbound API calls to a user-chosen provider — see §6.5 — but there is still
  no PDF2MD-operated backend.)
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

## 6. Technical Approach

> Engine and licensing decisions are **resolved** (2026-06-27). See
> [`OPENQUESTIONS.md`](./OPENQUESTIONS.md) for the record and the remaining
> defaults.

### 6.1 UI layer — **SwiftUI (native macOS app)**

- **Language:** Swift 5.9+
- **UI framework:** SwiftUI, targeting macOS 14+.
- **Why:** Native look and feel, smallest footprint, best fit for a MacBook Air,
  no runtime to bundle for the UI, easy access to native file/folder pickers
  (`NSOpenPanel` / `.fileImporter`) and Finder integration.

### 6.2 Conversion engine — **Swift + PDFKit (decided)**

The conversion engine is **Apple's PDFKit**, used directly from Swift. No
third-party conversion library is bundled.

- Use **PDFKit** to extract text and per-character layout/attributes, then apply
  heuristics to reconstruct Markdown structure (headings via font-size
  clustering, lists via bullet/indent detection, emphasis via font traits,
  tables via column/whitespace analysis).
- **Why chosen:** single language, no bundled runtime, smallest footprint, and —
  importantly — **clean licensing**: PDFKit is a first-party Apple framework, so
  there is no third-party engine license to clear (this is what resolves the
  earlier AGPL concern entirely).
- **Trade-off accepted:** more conversion logic to write ourselves, and table
  fidelity is weaker than a dedicated library. We treat heading/paragraph/list
  fidelity as the priority for v1.0 and table support as best-effort (FR-10 is
  "Should", not "Must").

Define a `PDFConverter` protocol so the engine remains swappable if a stronger
approach is ever needed; `PDFKitConverter` is the v1.0 implementation. The UI,
file handling, batching, and output logic are independent of the engine and can
be built in parallel.

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
│   ├── PDFKitConverter (impl)         // PDFKit text/layout -> Markdown heuristics
│   ├── BatchRunner                    // queues files, runs off main thread
│   ├── OutputWriter                   // naming, collision handling, writing .md
│   └── FileScanner                    // expand folders -> [PDF URLs]
└── Resources
    └── (app icon, assets — no bundled engine needed)
```

### 6.4 Key implementation notes

- Run conversions on a background queue/Task; keep the UI responsive and
  cancellable.
- Use security-scoped resource access for user-selected files/folders (required
  under macOS sandboxing if the app is sandboxed).
- Stream progress updates back to the UI on the main actor.
- Treat the converter as fallible per file; collect results, never crash a run.

### 6.5 AI (LLM) engine — opt-in, high-fidelity (added in `0.x`)

A second engine, `LLMConverter`, implements the same `PDFConverter` protocol
but uses a **vision LLM** to preserve formatting the heuristic engine can't
(tables, charts, complex layout):

- **Approach:** each page is rasterized (`PageRenderer`) and sent as an image
  to the selected provider with a transcribe-to-Markdown prompt; per-page
  results are concatenated. Vision is required because the goal is to reproduce
  the *visual* structure, which text extraction discards.
- **Providers:** Anthropic (Claude), OpenAI (ChatGPT), Google (Gemini), via raw
  HTTPS (`LLMClient`) — no third-party SDKs. Model IDs are user-editable.
- **Keys:** stored in the macOS **Keychain** (`Keychain`), never in plaintext.
- **Privacy trade-off:** this engine sends page images off-device to the chosen
  provider. It is opt-in, clearly labeled in the UI, and the local engine
  remains the default. Requires the `network.client` sandbox entitlement.
- **Async:** `PDFConverter.convert` is `async`; the local engine simply doesn't
  await anything, while the LLM engine awaits network calls. A failing page
  fails that one file; the batch continues.

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
├── BUILD.md                # how to build/run from source
├── LICENSE                 # MIT
├── .gitignore              # Xcode/Swift/macOS ignores
└── PDF2MD/                 # Xcode project
    ├── project.yml         # XcodeGen spec (canonical project definition)
    ├── PDF2MD.xcodeproj
    ├── PDF2MD/             # Swift sources
    │   ├── App/            # @main entry, entitlements
    │   ├── Core/           # PDFConverter, PDFKitConverter, BatchEngine, OutputWriter, FileScanner, Keychain
    │   │   └── LLM/        # PageRenderer, LLMProvider, LLMClient, LLMConverter (AI engine)
    │   ├── ViewModels/     # ConversionViewModel
    │   ├── Views/          # ContentView, ResultsView
    │   └── Assets.xcassets/
    └── PDF2MDTests/        # unit tests (naming, scanning, Markdown assembly)
```

> **Status:** This layout now exists as of milestone M1. See
> [`BUILD.md`](./BUILD.md) for how to open and run it.

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

| Milestone | Description | Status |
|-----------|-------------|--------|
| M0 — Brief | This document + supporting docs. | ✅ Done |
| M1 — Scaffolding | Xcode project, app skeleton, `PDFConverter` protocol, file pickers. | ✅ Done |
| M2 — Single-file | End-to-end single PDF → MD with output-folder selection. | ◑ Working baseline in place; needs on-device verification. |
| M3 — Batch | Multi-file/folder selection, background batch runner, progress + results. | ◑ Implemented; needs on-device verification. |
| M4 — Fidelity | Improve headings/lists/tables; collision handling polish. | ☐ Pending |
| M5 — Packaging | Build, sign/notarize (if applicable), produce distributable `.app`. | ☐ Pending |
| v1.0 | All Must requirements met; documented and packaged. | ☐ Pending |

> Note: M1 delivered a functional vertical slice that already exercises the M2
> (single-file) and M3 (batch) paths, since the UI, batching, and output layers
> are engine-agnostic. They are marked partial because they have not yet been
> built/run on a Mac — see "Verification" below.

### 8.1 Verification status

This scaffolding was authored in a Linux CI environment where Xcode is not
available, so the project has **not yet been compiled or run on macOS**. Before
relying on M2/M3, open the project per [`BUILD.md`](./BUILD.md), run the unit
tests (⌘U), and do a manual single-file and batch conversion. Any build fixes
should land as PATCH updates logged in [`CHANGELOG.md`](./CHANGELOG.md).

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

**Resolved (2026-06-27):** conversion engine (PDFKit), engine licensing (none —
first-party framework), overwrite default (numeric suffix), and project license
(MIT).

**Remaining**, all with working defaults that do not block starting M1 —
minimum macOS version (default 14), sandboxing/notarization (deferred to M5),
OCR scope (excluded from v1.0), recursive folder scanning (default off), and
app name/bundle id (PDF2MD / `com.johnjanney.pdf2md`) — are tracked in
[`OPENQUESTIONS.md`](./OPENQUESTIONS.md) and confirmed at the relevant milestone.

The main residual *technical* risk is **table fidelity** from PDFKit's
heuristic-based reconstruction; mitigated by treating tables as best-effort
(FR-10) and keeping the engine swappable behind the `PDFConverter` protocol.
