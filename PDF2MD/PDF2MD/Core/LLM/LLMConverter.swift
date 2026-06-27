import Foundation
import PDFKit

/// PDF → Markdown converter that uses a vision LLM to preserve formatting
/// (headings, tables, charts, layout).
///
/// Each page is rasterized and sent to the selected provider; the per-page
/// Markdown is concatenated. This is the higher-fidelity, opt-in alternative
/// to `PDFKitConverter` — it requires an API key and network access, and the
/// page images are sent to the chosen provider.
struct LLMConverter: PDFConverter {
    let provider: LLMProvider
    let model: String
    let apiKey: String
    var insertPageSeparators: Bool = false

    func convert(pdfAt url: URL) async throws -> MarkdownDocument {
        guard let document = PDFDocument(url: url) else {
            throw ConversionError.cannotOpenPDF(url)
        }
        if document.isEncrypted && document.isLocked {
            throw ConversionError.pdfIsEncrypted(url)
        }

        let renderer = PageRenderer()
        let client = LLMClient()
        var pageMarkdowns: [String] = []

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let imageBase64 = renderer.renderPNGBase64(page: page) else { continue }
            let markdown = try await client.convertImage(provider: provider,
                                                         model: model,
                                                         apiKey: apiKey,
                                                         imageBase64: imageBase64)
            pageMarkdowns.append(markdown.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let separator = insertPageSeparators ? "\n\n---\n\n" : "\n\n"
        let markdown = pageMarkdowns.filter { !$0.isEmpty }.joined(separator: separator)
        guard !markdown.isEmpty else {
            throw ConversionError.noTextFound(url)
        }

        let title = Self.firstMarkdownHeading(in: markdown)
        return MarkdownDocument(markdown: markdown + "\n", pageCount: document.pageCount, title: title)
    }

    /// Extract the first ATX heading (`# ...`) to use as the document title.
    static func firstMarkdownHeading(in markdown: String) -> String? {
        for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#") else { continue }
            let text = line.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
            if !text.isEmpty { return text }
        }
        return nil
    }
}
