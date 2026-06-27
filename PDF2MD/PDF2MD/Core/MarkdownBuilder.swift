import Foundation

/// A single logical line extracted from a PDF page, with the typographic
/// hints the converter uses to reconstruct Markdown structure.
struct TextLine: Equatable {
    var text: String
    /// Point size of the dominant font on this line (0 for blank lines).
    var fontSize: Double
    var isBold: Bool
    var isItalic: Bool
    /// True if the line begins with a bullet/number marker.
    var isBullet: Bool
}

/// Assembles `TextLine` values into Markdown.
///
/// This is deliberately heuristic for v1.0 (see PROJECTBRIEF.md — fidelity is
/// improved at milestone M4). It groups consecutive body lines into
/// paragraphs, consecutive bullet lines into tight lists, and promotes
/// larger-font short lines to headings.
struct MarkdownBuilder {
    /// Font-size ratio thresholds (relative to body text) → heading level.
    /// Ordered largest-first.
    private static let headingThresholds: [(ratio: Double, prefix: String)] = [
        (1.8, "# "),
        (1.5, "## "),
        (1.25, "### "),
        (1.1, "#### "),
    ]

    /// A line longer than this is treated as a paragraph even if its font is
    /// large, since real headings are short.
    private static let maxHeadingLength = 120

    private var blocks: [String] = []
    private var paragraph: [String] = []
    private var listItems: [String] = []

    /// Add one line to the document.
    mutating func add(line: TextLine, bodySize: Double) {
        let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            flushParagraph()
            flushList()
            return
        }

        if line.isBullet {
            flushParagraph()
            listItems.append("- " + Self.stripBulletMarker(from: text))
            return
        }

        flushList()

        if let prefix = headingPrefix(for: line, bodySize: bodySize), text.count <= Self.maxHeadingLength {
            flushParagraph()
            blocks.append(prefix + text)
        } else {
            paragraph.append(text)
        }
    }

    /// Insert a horizontal rule (used for optional page separators).
    mutating func addThematicBreak() {
        flushParagraph()
        flushList()
        blocks.append("---")
    }

    /// Finalize and return the assembled Markdown.
    mutating func build() -> String {
        flushParagraph()
        flushList()
        let body = blocks.joined(separator: "\n\n")
        return body.isEmpty ? "" : body + "\n"
    }

    // MARK: - Private

    private func headingPrefix(for line: TextLine, bodySize: Double) -> String? {
        guard bodySize > 0, line.fontSize > 0 else { return nil }
        let ratio = line.fontSize / bodySize
        for threshold in Self.headingThresholds where ratio >= threshold.ratio {
            return threshold.prefix
        }
        return nil
    }

    private mutating func flushParagraph() {
        guard !paragraph.isEmpty else { return }
        // Join hard-wrapped lines into a single paragraph.
        blocks.append(paragraph.joined(separator: " "))
        paragraph.removeAll(keepingCapacity: true)
    }

    private mutating func flushList() {
        guard !listItems.isEmpty else { return }
        blocks.append(listItems.joined(separator: "\n"))
        listItems.removeAll(keepingCapacity: true)
    }

    /// Remove a leading bullet glyph or "1." / "1)" numbering from a line.
    static func stripBulletMarker(from text: String) -> String {
        // Glyph bullets.
        if let first = text.first, "•◦▪–-*‣·".contains(first) {
            return String(text.dropFirst()).trimmingCharacters(in: .whitespaces)
        }
        // Numbered: leading digits followed by . or )
        let digits = text.prefix { $0.isNumber }
        if !digits.isEmpty {
            let rest = text.dropFirst(digits.count)
            if let marker = rest.first, marker == "." || marker == ")" {
                return String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
        }
        return text
    }
}
