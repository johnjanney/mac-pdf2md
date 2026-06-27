import Foundation

/// The result of converting a single PDF file to Markdown.
struct MarkdownDocument: Sendable {
    /// The generated Markdown text.
    let markdown: String
    /// Number of pages read from the source PDF.
    let pageCount: Int
    /// Best-effort document title (embedded metadata or first heading), if any.
    /// Used to name the output file when the user opts in.
    var title: String? = nil
}

/// Errors that can occur while converting or writing a PDF.
///
/// Cases carry a `String` message rather than an underlying `Error` so the
/// type stays `Sendable` and can cross actor/task boundaries cleanly.
enum ConversionError: LocalizedError, Sendable {
    case cannotOpenPDF(URL)
    case pdfIsEncrypted(URL)
    case noTextFound(URL)
    case writeFailed(URL, reason: String)

    var errorDescription: String? {
        switch self {
        case .cannotOpenPDF(let url):
            return "Couldn't open \"\(url.lastPathComponent)\" — the file may be corrupt or not a valid PDF."
        case .pdfIsEncrypted(let url):
            return "\"\(url.lastPathComponent)\" is password-protected and can't be read."
        case .noTextFound(let url):
            return "No selectable text found in \"\(url.lastPathComponent)\" — it may be a scanned image (OCR is not supported yet)."
        case .writeFailed(let url, let reason):
            return "Couldn't write \"\(url.lastPathComponent)\": \(reason)"
        }
    }
}

/// Converts a single PDF file into a Markdown document.
///
/// The engine is intentionally abstracted behind this protocol so the
/// underlying implementation (PDFKit in v1.0) can be swapped without touching
/// the UI, batching, or output layers. See PROJECTBRIEF.md section 6.
protocol PDFConverter: Sendable {
    /// Convert the PDF at `url` into Markdown.
    /// - Throws: `ConversionError` if the file can't be opened, is encrypted,
    ///   or contains no extractable text.
    func convert(pdfAt url: URL) throws -> MarkdownDocument
}
