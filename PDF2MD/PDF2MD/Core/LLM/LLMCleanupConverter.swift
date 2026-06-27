import Foundation

/// PDF → Markdown converter for the **post-process** mode: the local PDFKit
/// engine extracts text first, then an LLM tidies that Markdown (fixing run-on
/// line breaks, broken paragraphs, and mangled lists/tables).
///
/// Cheaper and faster than the vision engine, and works with text-only models
/// (e.g. DeepSeek) since no image is sent. If the LLM step fails, the locally
/// extracted Markdown is kept rather than failing the file outright.
struct LLMCleanupConverter: PDFConverter {
    let provider: LLMProvider
    let model: String
    let apiKey: String
    var insertPageSeparators: Bool = false

    func convert(pdfAt url: URL) async throws -> MarkdownDocument {
        // 1. Local extraction (also surfaces cannot-open / encrypted / no-text).
        let base = try await PDFKitConverter(insertPageSeparators: insertPageSeparators).convert(pdfAt: url)

        // 2. Ask the LLM to tidy the extracted Markdown.
        let cleaned = try await LLMClient().cleanup(provider: provider,
                                                    model: model,
                                                    apiKey: apiKey,
                                                    markdown: base.markdown)
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }

        let title = LLMConverter.firstMarkdownHeading(in: trimmed) ?? base.title
        return MarkdownDocument(markdown: trimmed + "\n", pageCount: base.pageCount, title: title)
    }
}
