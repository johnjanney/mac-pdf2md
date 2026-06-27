# PDF2MD — Instructions

How to use the PDF2MD macOS app to convert PDF files into Markdown.

> **Note:** The app is not yet built. This document describes the intended
> user experience so the implementation can be built to match it, and so the
> instructions are ready when the first release ships. Steps marked *(planned)*
> may change during development.

---

## Installing the app *(planned)*

1. Download the latest `PDF2MD.app` (or `.dmg`) from the releases page.
2. If you downloaded a `.dmg`, open it and drag **PDF2MD** into your
   **Applications** folder.
3. The first time you open it, macOS may warn that it's from an unidentified
   developer. If so, right-click the app and choose **Open**, then confirm.
   (This step goes away once the app is notarized — see the project's open
   questions.)

---

## Converting a single PDF

1. Open **PDF2MD**.
2. Click **Choose PDF…** (or drag a PDF onto the window).
3. Click **Choose Output Folder…** and pick where you want the `.md` file
   saved.
4. Click **Convert**.
5. When it finishes, you'll see a success message. Click **Open in Finder** to
   jump to your new `name.md` file.

Your `document.pdf` becomes `document.md` in the folder you chose.

---

## Converting many PDFs (batch)

You can convert multiple PDFs at once in either of two ways:

### Option A — select multiple files

1. Click **Choose PDFs…**.
2. In the file picker, select several PDFs (Cmd-click or Shift-click).
3. Choose your **Output Folder**.
4. Click **Convert**. Each PDF becomes its own `.md` file.

### Option B — select a whole folder

1. Click **Choose Folder…**.
2. Pick a folder that contains PDFs. The app finds every PDF inside it.
   *(A toggle to include subfolders is planned.)*
3. Choose your **Output Folder**.
4. Click **Convert**.

While a batch runs, you'll see live progress (which file is converting and how
many remain). When it's done, a summary lists each file as **succeeded** or
**failed** (with a short reason for any failures). A single problem PDF will not
stop the rest of the batch.

---

## Choosing the output folder

- The output folder is where all converted `.md` files are written.
- You must select an output folder before converting.
- The app remembers your last-used output folder for convenience *(planned)*.

---

## Choosing a conversion engine

PDF2MD has two engines, selectable in the **Conversion engine** section:

### Local (default)
- Fast, **fully offline**, and free. Nothing leaves your Mac.
- Good for text-based PDFs with clear headings, lists, and simple tables.
- Tables and complex layouts are best-effort.

### AI — preserves formatting
- Renders each page and sends it to an AI vision model that transcribes it to
  Markdown, **preserving headings, tables, and charts** much more faithfully.
- Requires your own API key from one of: **Anthropic (Claude)**,
  **OpenAI (ChatGPT)**, or **Google (Gemini)**.
- **Provider note:** for faithful transcription, **Anthropic (Claude)** tends to
  give the best results. **Gemini** sometimes refuses verbatim transcription
  with a `RECITATION` block (its copyright filter) — if you hit that, switch to
  Claude or OpenAI.
- ⚠️ **Privacy:** with the AI engine, each page image is sent to the provider
  you choose. Use the Local engine if documents must never leave your Mac.
- Slower and incurs cost from your provider (billed by them, per their pricing).

### Setting up the AI engine
1. Open **PDF2MD → Settings** (⌘,).
2. Choose **AI** as the engine and pick your **Provider**.
3. Paste your **API key** for that provider (get one from the "Get key" link).
   You can optionally change the **Model** if you want a specific one.
4. Click **Save Keys**. Keys are stored securely in your **macOS Keychain**.
5. Back in the main window, pick **AI**, choose the provider, and **Convert**.

---

## How output files are named

- By default (the **"Name files by the document's title"** option), each `.md`
  is named after the document's title — taken from the **first heading** on the
  page, falling back to the PDF's embedded title only if no heading is found.
- If no title can be detected, the app falls back to the PDF's filename
  (`report.pdf` → `report.md`).
- Turn the option off to always use the PDF's filename instead.
- Titles are cleaned up for use as filenames (illegal characters removed, very
  long titles shortened).

## What happens to existing files?

- If a `.md` file with the same name already exists in the output folder, the
  app will **not** overwrite it silently. By default it saves a new copy with a
  numbered suffix, e.g. `document-1.md`.

---

## What converts well (and what doesn't)

**Works well:**

- Text-based PDFs (exported from word processors, browsers, etc.).
- Documents with clear headings, paragraphs, lists, and simple tables.

**Limited or not supported in v1.0:**

- **Scanned PDFs / images of text** — these contain no selectable text, so
  there is nothing to convert. OCR support is a possible future feature.
- Very complex layouts (multi-column magazines, heavy graphics) may not
  reconstruct perfectly.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| "Convert" is disabled | Make sure you've selected at least one PDF **and** an output folder. |
| A file shows as "failed" | The PDF may be corrupt, password-protected, or image-only (scanned). |
| Output looks empty | The PDF is likely a scanned image with no text layer. |
| macOS won't open the app | Right-click the app → **Open**, then confirm (unidentified developer). |

---

## Privacy

PDF2MD does all conversion **on your Mac**. It makes no network connections and
collects no analytics. Your documents never leave your computer.

---

## Getting help / reporting issues

Please file issues on the project's GitHub repository. Include the macOS
version, the app version (see **PDF2MD → About**), and — if possible — a sample
PDF that reproduces the problem.
