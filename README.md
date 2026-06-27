# PDF2MD

A native macOS app that converts PDF files into clean Markdown (`.md`) files —
fast, private, and fully offline. Built for everyday use on a MacBook Air.

> **Status:** 🚧 Pre-development. This repository currently contains the project
> brief and planning docs only — no application code has been written yet. See
> [`PROJECTBRIEF.md`](./PROJECTBRIEF.md) for the full plan.

---

## Why PDF2MD?

Turning PDFs into editable Markdown usually means pasting into a web tool and
hoping the document never leaves your control. PDF2MD does the conversion
**locally on your Mac** — your documents stay on your machine.

## Features (planned for v1.0)

- 📄 **Single-file conversion** — pick one PDF, get one `.md`.
- 📚 **Batch conversion** — convert many PDFs, or an entire folder, in one run.
- 📁 **Choose your output folder** — you decide where the `.md` files go.
- 🧱 **Structure-aware** — preserves headings, paragraphs, lists, and tables
  where detectable.
- 🔒 **Offline & private** — no network calls, no telemetry.
- 🍎 **Native macOS** — built with SwiftUI for a clean Mac feel.

## Status & roadmap

This project is in the **brief/planning** phase. The implementation roadmap and
milestones live in [`PROJECTBRIEF.md`](./PROJECTBRIEF.md). Open decisions are
tracked in [`OPENQUESTIONS.md`](./OPENQUESTIONS.md).

## Requirements (target)

- macOS 14 (Sonoma) or later — *to be confirmed*
- Apple Silicon Mac (MacBook Air M1 or newer recommended)

## Installation

> Not yet available — there is no build to install. Installation instructions
> will be added here once the first release is published.

## Build It
Build the standalone app
1. In Xcode, make sure the destination at the top says My Mac (not a simulator).
2. Menu bar: Product → Archive. Wait for it to build (Archive always uses the optimized Release build). A window called Organizer opens with your archive listed.
3. Click Distribute App (button on the right).
4. Choose Custom → Next.
5. Choose Copy App → Next. (This exports the app as-is, signed to run on your Mac — no Apple Developer account or notarization needed.)
6. Pick a location to save it (e.g., Desktop) → Export.
You'll get a folder containing PDF2MD.app.

Install it
* Drag PDF2MD.app into your Applications folder.
* Launch it from Launchpad or Spotlight (⌘Space → "PDF2MD").
* First launch only: if macOS says it's from an unidentified developer, right-click the app → Open → Open. After that it opens normally by double-click.
That's it — it's now a normal Mac app, no Xcode required to run it.

## Usage

See [`INSTRUCTIONS.md`](./INSTRUCTIONS.md) for how to use the app once it is
built.

## Documentation

| Document | Purpose |
|----------|---------|
| [`PROJECTBRIEF.md`](./PROJECTBRIEF.md) | Scope, requirements, architecture, milestones. |
| [`INSTRUCTIONS.md`](./INSTRUCTIONS.md) | How to use the app. |
| [`CHANGELOG.md`](./CHANGELOG.md) | Record of changes + versioning policy. |
| [`OPENQUESTIONS.md`](./OPENQUESTIONS.md) | Unresolved decisions. |

## Versioning

This project uses [Semantic Versioning](https://semver.org/). See the
[versioning policy](./PROJECTBRIEF.md#9-versioning-policy-semantic-versioning)
and [`CHANGELOG.md`](./CHANGELOG.md).

## License

Released under the [MIT License](./LICENSE).
