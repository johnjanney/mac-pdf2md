import Foundation

/// Expands a user selection (a mix of PDF files and folders) into a flat,
/// de-duplicated, sorted list of PDF file URLs.
struct FileScanner: Sendable {
    /// When true, folders are scanned recursively into subfolders.
    var includeSubfolders: Bool = false

    func pdfURLs(from inputs: [URL]) -> [URL] {
        let fm = FileManager.default
        var collected: [URL] = []

        for url in inputs {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
            if isDir.boolValue {
                collected.append(contentsOf: pdfs(inFolder: url, fm: fm))
            } else if url.pathExtension.lowercased() == "pdf" {
                collected.append(url)
            }
        }

        // De-duplicate by standardized path, preserving order, then sort by name.
        var seen = Set<String>()
        let unique = collected.filter { seen.insert($0.standardizedFileURL.path).inserted }
        return unique.sorted {
            $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
        }
    }

    private func pdfs(inFolder folder: URL, fm: FileManager) -> [URL] {
        let options: FileManager.DirectoryEnumerationOptions =
            includeSubfolders ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        guard let enumerator = fm.enumerator(at: folder,
                                             includingPropertiesForKeys: [.isRegularFileKey],
                                             options: options) else {
            return []
        }
        var result: [URL] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension.lowercased() == "pdf" {
            result.append(fileURL)
        }
        return result
    }
}
