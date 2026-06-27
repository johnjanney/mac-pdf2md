# Open Questions

Unresolved decisions for PDF2MD. Each should be answered at or before the
milestone noted. Resolved items should be moved to the "Resolved" section with
the decision and date.

---

## Open

### 1. Conversion engine — which approach? *(blocks M2)*
The biggest technical decision. Two candidates from the brief:

- **Option A — bundled Python engine** (e.g. `pymupdf4llm`): best Markdown
  fidelity (tables, headings) with less custom code, but larger bundle and a
  licensing concern (see Q2).
- **Option B — pure Swift + PDFKit**: smallest footprint, single language,
  clean licensing, but more conversion logic to write and weaker table support.

**Recommendation:** Start by prototyping Option B (PDFKit) for a license-clean,
native build; fall back to Option A if fidelity is inadequate. Confirm.

### 2. Conversion library licensing *(blocks engine choice if Option A)*
PyMuPDF / `pymupdf4llm` is **AGPL-licensed**, which has implications for
distributing a closed-source app. Need to confirm whether the license is
acceptable, whether a commercial license is needed, or whether to pick a
differently-licensed library (e.g. `markitdown`, `docling`) or Option B.

### 3. Minimum supported macOS version *(blocks M1)*
Brief assumes **macOS 14 (Sonoma)+**. Confirm the oldest macOS the user needs
to run on (affects available SwiftUI APIs).

### 4. App sandboxing & distribution *(blocks M5)*
- Will the app be sandboxed (required for App Store, optional otherwise)?
- How will it be distributed: notarized `.dmg` outside the App Store, the Mac
  App Store, or unsigned for personal use only?
- Notarization requires a paid Apple Developer account ($99/yr) — is that
  available? This affects the "unidentified developer" warning in
  `INSTRUCTIONS.md`.

### 5. Overwrite vs. suffix default *(blocks M2)*
When an output `.md` already exists, default behavior is proposed as
"save with numeric suffix" (`document-1.md`). Confirm whether the default should
instead be "ask each time" or "overwrite," and whether to expose a setting.

### 6. OCR for scanned PDFs *(future / scope)*
v1.0 explicitly excludes OCR. Confirm this is acceptable for the first release.
If wanted later, decide between Apple's Vision framework (native, free) vs. a
bundled OCR engine. Tracked as a candidate MINOR release feature.

### 7. Project license *(blocks first public release)*
What license should the repository use (MIT, Apache-2.0, proprietary, etc.)?
A `LICENSE` file must be added before release. Note this interacts with Q2 if a
copyleft dependency is chosen.

### 8. Recursive folder scanning *(nice-to-have for M3)*
Should folder selection include PDFs in subfolders? Proposed as an optional
toggle (default off). Confirm.

### 9. App name & bundle identifier *(blocks M1)*
Working name is **PDF2MD**. Confirm the final display name and the bundle
identifier (e.g. `com.johnjanney.pdf2md`).

---

## Resolved

_None yet._

<!--
When resolving, move the item here in this form:

### [Resolved YYYY-MM-DD] <question title>
**Decision:** ...
**Rationale:** ...
-->
