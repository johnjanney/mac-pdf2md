import Foundation

/// Writes Markdown documents into the user-selected output folder, applying
/// the project's collision policy.
///
/// Default policy (see OPENQUESTIONS.md, resolved): never overwrite silently —
/// append a numeric suffix (`name-1.md`, `name-2.md`). The writer also reserves
/// names *within a batch* so two source files that map to the same output name
/// don't clobber each other.
///
/// Marked `@unchecked Sendable`: instances are used by a single actor-isolated
/// batch run at a time, so the internal `reserved` set is never touched
/// concurrently.
final class OutputWriter: @unchecked Sendable {
    private let folder: URL
    private let overwrite: Bool
    private var reserved = Set<String>()

    init(folder: URL, overwrite: Bool = false) {
        self.folder = folder
        self.overwrite = overwrite
    }

    /// Write `document` for a source whose base name (without extension) is
    /// `baseName`. Returns the URL actually written.
    @discardableResult
    func write(_ document: MarkdownDocument, sourceName baseName: String) throws -> URL {
        let url = reserveURL(for: sanitize(baseName))
        do {
            try document.markdown.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ConversionError.writeFailed(url, reason: error.localizedDescription)
        }
        return url
    }

    // MARK: - Private

    private func candidate(_ name: String) -> URL {
        folder.appendingPathComponent(name).appendingPathExtension("md")
    }

    private func reserveURL(for base: String) -> URL {
        if overwrite {
            let url = candidate(base)
            reserved.insert(url.lastPathComponent.lowercased())
            return url
        }

        let fm = FileManager.default
        var name = base
        var counter = 1
        while reserved.contains(candidate(name).lastPathComponent.lowercased())
                || fm.fileExists(atPath: candidate(name).path) {
            name = "\(base)-\(counter)"
            counter += 1
        }
        reserved.insert(candidate(name).lastPathComponent.lowercased())
        return candidate(name)
    }

    /// Strip path separators and trim so a base name is a safe single filename.
    private func sanitize(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : cleaned
    }
}
