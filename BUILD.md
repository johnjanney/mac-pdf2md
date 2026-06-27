# Building PDF2MD

This document is for developers building the app from source. End users should
see [`INSTRUCTIONS.md`](./INSTRUCTIONS.md).

## Requirements

- macOS 14 (Sonoma) or later
- **Xcode 16 or later** (the project uses file-system–synchronized groups,
  `objectVersion 77`)

## Open and run

```sh
open PDF2MD/PDF2MD.xcodeproj
```

Then in Xcode:

1. Select the **PDF2MD** scheme (top toolbar) and **My Mac** as the destination.
2. The first time, open **Signing & Capabilities** for the PDF2MD target and set
   the Team to your Apple ID, or choose **"Sign to Run Locally"**. This is a
   one-time local-signing step; no paid Apple Developer account is required just
   to build and run on your own Mac.
3. Press **⌘R** to build and run, or **⌘U** to run the unit tests.

## Build / test from the command line

```sh
cd PDF2MD
xcodebuild -scheme PDF2MD -destination 'platform=macOS' build
xcodebuild -scheme PDF2MD -destination 'platform=macOS' test
```

## Regenerating the Xcode project (optional)

`PDF2MD.xcodeproj` is committed, but it can be regenerated from
[`PDF2MD/project.yml`](./PDF2MD/project.yml) — useful if the committed project
ever fails to open on your Xcode version, or after large structural changes.

```sh
brew install xcodegen      # one-time
cd PDF2MD
xcodegen generate
open PDF2MD.xcodeproj
```

`project.yml` is the canonical source of truth for project structure and build
settings.

## App icon

A helper script generates the full macOS icon set (all 10 sizes +
`Contents.json`) using only built-in Apple frameworks — no installs. Run it
from the repo root:

```sh
# Draw the built-in PDF→MD icon:
swift PDF2MD/Tools/GenerateAppIcon.swift

# …or slice your own square 1024×1024 PNG instead:
swift PDF2MD/Tools/GenerateAppIcon.swift /path/to/my-icon-1024.png
```

It writes into `PDF2MD/PDF2MD/Assets.xcassets/AppIcon.appiconset`. Rebuild in
Xcode afterward (Clean Build Folder, ⇧⌘K, if the old icon is cached).

You can also set the icon by hand in Xcode: open
`Assets.xcassets → AppIcon` and drag images into the slots.

## Project layout

```
PDF2MD/
├── project.yml                 # XcodeGen spec (canonical project definition)
├── PDF2MD.xcodeproj            # Pre-generated Xcode project
├── PDF2MD/                     # App sources (auto-synchronized into the target)
│   ├── App/                    # @main entry, entitlements
│   ├── Core/                   # PDFConverter protocol, PDFKit engine, batching, I/O
│   ├── ViewModels/             # ConversionViewModel
│   ├── Views/                  # SwiftUI views
│   └── Assets.xcassets/        # App icon, accent color
└── PDF2MDTests/                # XCTest unit tests
```

Because the app and test folders are **synchronized groups**, any `.swift` file
you add under `PDF2MD/PDF2MD/` or `PDF2MD/PDF2MDTests/` is picked up
automatically — no need to edit the project file.

## Architecture notes

- The conversion engine is hidden behind the `PDFConverter` protocol
  (`Core/PDFConverter.swift`); `PDFKitConverter` is the v1.0 implementation.
- `BatchEngine` is an `actor`, so conversion runs off the main thread and the
  UI stays responsive. Progress is streamed back via an `AsyncStream`.
- `OutputWriter` enforces the no-silent-overwrite policy (numeric suffixes).
- See [`PROJECTBRIEF.md`](./PROJECTBRIEF.md) section 6 for the full design.
