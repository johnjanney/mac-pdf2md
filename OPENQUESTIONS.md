# Open Questions

Unresolved decisions for PDF2MD. Each should be answered at or before the
milestone noted. Resolved items should be moved to the "Resolved" section with
the decision and date.

---

## Open

> The remaining items below have **working defaults** that implementation will
> proceed with. They are "open" only in that the user can override them later;
> none block starting M1. The one item with real-world cost (Q4, notarization)
> is deferred to M5.

### 3. Minimum supported macOS version *(default set; confirm by M1)*
**Default:** macOS 14 (Sonoma) or later. Revisit only if the app must run on an
older Mac.

### 4. App sandboxing & distribution *(deferred to M5)*
**Default for development:** build for **local/personal use, unsigned**, with
App Sandbox enabled and the user-selected-files entitlement (needed for the
file/folder pickers). Decision deferred:
- Notarized `.dmg` for distribution vs. Mac App Store vs. personal-only.
- Notarization requires a paid Apple Developer account ($99/yr). Needed only
  when distributing beyond your own machine; affects the "unidentified
  developer" note in `INSTRUCTIONS.md`.

### 6. OCR for scanned PDFs *(future / scope)*
**Default:** excluded from v1.0. If wanted later, Apple's **Vision** framework
(native, free, no license concern) is the natural fit. Tracked as a candidate
MINOR release feature.

### 8. Recursive folder scanning *(nice-to-have for M3)*
**Default:** optional toggle, **off** by default. Confirm at M3.

### 9. App name & bundle identifier *(default set; confirm by M1)*
**Default:** display name **PDF2MD**, bundle id **`com.johnjanney.pdf2md`**.

---

## Resolved

### [Resolved 2026-06-27] 1. Conversion engine
**Decision:** Swift + **PDFKit** (Apple first-party framework), with a
`PDFConverter` protocol so the engine stays swappable.
**Rationale:** Native, smallest footprint, no bundled runtime, and clean
licensing. Table fidelity is weaker than a dedicated library, which is an
accepted trade-off (tables are a "Should", not a "Must", for v1.0).

### [Resolved 2026-06-27] 2. Conversion library licensing
**Decision:** No third-party conversion library. PDFKit is part of macOS, so
there is **no engine license to clear** — the earlier AGPL (PyMuPDF) concern is
moot.
**Rationale:** Choosing PDFKit (Q1) removes the dependency entirely.

### [Resolved 2026-06-27] 5. Overwrite vs. suffix default
**Decision:** Never overwrite silently. Default to a numeric suffix
(`document-1.md`, `document-2.md`). An "Overwrite existing" option may be added
later.
**Rationale:** Safe default; protects against accidental data loss in batch runs.

### [Resolved 2026-06-27] 7. Project license
**Decision:** **MIT License.** A `LICENSE` file has been added to the repo.
**Rationale:** Simplest permissive license, no obligations, compatible with the
all-first-party-framework approach. User deferred the choice; MIT recommended.

<!--
When resolving, move the item here in this form:

### [Resolved YYYY-MM-DD] <question title>
**Decision:** ...
**Rationale:** ...
-->
