import Foundation
import PDFKit
import AppKit

/// PDF → Markdown converter built on Apple's PDFKit.
///
/// This is a first-party-only implementation: no third-party libraries, no
/// bundled runtime. It reads each page's attributed text, learns the document's
/// body font size, and uses font-size/marker heuristics to reconstruct
/// headings, paragraphs, and lists. Table reconstruction is out of scope for
/// the v1.0 baseline (see PROJECTBRIEF.md, FR-10 / milestone M4).
struct PDFKitConverter: PDFConverter {
    /// When true, a `---` rule is inserted between pages.
    var insertPageSeparators: Bool = false

    func convert(pdfAt url: URL) throws -> MarkdownDocument {
        guard let document = PDFDocument(url: url) else {
            throw ConversionError.cannotOpenPDF(url)
        }
        if document.isEncrypted && document.isLocked {
            throw ConversionError.pdfIsEncrypted(url)
        }

        // First pass: extract lines for every page.
        var pages: [[TextLine]] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            pages.append(Self.extractLines(from: page))
        }

        // Learn the body text size so headings can be detected relatively.
        let bodySize = Self.estimateBodyFontSize(in: pages)
        guard bodySize > 0 else {
            throw ConversionError.noTextFound(url)
        }

        // Second pass: assemble Markdown.
        var builder = MarkdownBuilder()
        for (pageIndex, lines) in pages.enumerated() {
            if insertPageSeparators && pageIndex > 0 {
                builder.addThematicBreak()
            }
            for line in lines {
                builder.add(line: line, bodySize: bodySize)
            }
        }

        let markdown = builder.build()
        guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConversionError.noTextFound(url)
        }
        return MarkdownDocument(markdown: markdown, pageCount: document.pageCount)
    }

    // MARK: - Extraction

    /// Pull lines (with font hints) from a single page.
    static func extractLines(from page: PDFPage) -> [TextLine] {
        guard let attributed = page.attributedString, attributed.length > 0 else { return [] }
        let full = attributed.string as NSString
        var lines: [TextLine] = []

        full.enumerateSubstrings(in: NSRange(location: 0, length: full.length),
                                 options: [.byLines, .substringNotRequired]) { _, range, _, _ in
            let raw = full.substring(with: range)
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                lines.append(TextLine(text: "", fontSize: 0, isBold: false, isItalic: false, isBullet: false))
                return
            }

            let font = attributed.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
            let size = Double(font?.pointSize ?? 0)
            let traits = font?.fontDescriptor.symbolicTraits ?? []
            let bullet = Self.looksLikeBullet(trimmed)

            lines.append(TextLine(text: raw,
                                  fontSize: size,
                                  isBold: traits.contains(.bold),
                                  isItalic: traits.contains(.italic),
                                  isBullet: bullet))
        }
        return lines
    }

    /// True if a line begins with a bullet glyph or "1." / "1)" numbering.
    static func looksLikeBullet(_ text: String) -> Bool {
        guard let first = text.first else { return false }
        if "•◦▪‣·".contains(first) { return true }
        if (first == "-" || first == "*"), text.dropFirst().first == " " { return true }
        // Numbered list: digits then . or )
        let digits = text.prefix { $0.isNumber }
        if !digits.isEmpty {
            let rest = text.dropFirst(digits.count)
            if let marker = rest.first, marker == "." || marker == ")" { return true }
        }
        return false
    }

    /// Estimate the document's body font size as the most common rounded size,
    /// weighted by how much text uses it.
    static func estimateBodyFontSize(in pages: [[TextLine]]) -> Double {
        var weight: [Int: Int] = [:]
        for page in pages {
            for line in page where line.fontSize > 0 {
                let key = Int(line.fontSize.rounded())
                weight[key, default: 0] += max(1, line.text.count)
            }
        }
        guard let mode = weight.max(by: { $0.value < $1.value })?.key else { return 0 }
        return Double(mode)
    }
}
