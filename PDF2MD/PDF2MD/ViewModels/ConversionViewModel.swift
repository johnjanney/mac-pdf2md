import Foundation
import SwiftUI
import AppKit

/// Drives the conversion UI: holds the user's selections, runs the batch, and
/// publishes progress and results back to the views.
@MainActor
final class ConversionViewModel: ObservableObject {
    // Selections
    @Published var inputURLs: [URL] = []
    @Published var outputFolder: URL?
    @Published var includeSubfolders = false
    @Published var insertPageSeparators = false
    /// Name each output `.md` after the document's title when one is detected
    /// (falling back to the PDF's filename).
    @Published var nameByTitle = true

    // Run state
    @Published private(set) var isConverting = false
    @Published private(set) var completed = 0
    @Published private(set) var total = 0
    @Published private(set) var currentFileName = ""
    @Published private(set) var outcomes: [ConversionOutcome] = []
    @Published var statusMessage: String?

    private let engine = BatchEngine()

    var canConvert: Bool {
        !inputURLs.isEmpty && outputFolder != nil && !isConverting
    }

    var inputSummary: String {
        guard !inputURLs.isEmpty else { return "No PDFs or folders selected" }
        let folders = inputURLs.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }.count
        let files = inputURLs.count - folders
        var parts: [String] = []
        if files > 0 { parts.append("\(files) file\(files == 1 ? "" : "s")") }
        if folders > 0 { parts.append("\(folders) folder\(folders == 1 ? "" : "s")") }
        return parts.joined(separator: ", ") + " selected"
    }

    var outputSummary: String {
        outputFolder?.path ?? "No output folder selected"
    }

    var successCount: Int { outcomes.filter(\.didSucceed).count }
    var failureCount: Int { outcomes.count - successCount }

    // MARK: - Selection handling

    func addInputs(from result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        var existing = Set(inputURLs.map(\.standardizedFileURL.path))
        for url in urls where existing.insert(url.standardizedFileURL.path).inserted {
            inputURLs.append(url)
        }
        statusMessage = nil
    }

    func setOutputFolder(from result: Result<[URL], Error>) {
        if case .success(let urls) = result, let folder = urls.first {
            outputFolder = folder
        }
    }

    func clearInputs() {
        inputURLs.removeAll()
        outcomes.removeAll()
        statusMessage = nil
    }

    // MARK: - Conversion

    /// Start a batch conversion using the supplied engine. The caller builds
    /// the `converter` from the current settings (local PDFKit or LLM).
    func startConversion(converter: PDFConverter) {
        guard let output = outputFolder, !inputURLs.isEmpty, !isConverting else { return }

        let inputs = inputURLs
        let scanner = FileScanner(includeSubfolders: includeSubfolders)
        let useTitleForName = nameByTitle

        isConverting = true
        outcomes = []
        completed = 0
        total = 0
        currentFileName = ""
        statusMessage = nil

        Task {
            // Acquire access to user-selected locations (required under sandbox).
            let scoped = (inputs + [output]).filter { $0.startAccessingSecurityScopedResource() }
            defer { scoped.forEach { $0.stopAccessingSecurityScopedResource() } }

            let pdfs = scanner.pdfURLs(from: inputs)
            guard !pdfs.isEmpty else {
                isConverting = false
                statusMessage = "No PDF files were found in the selection."
                return
            }
            total = pdfs.count

            let writer = OutputWriter(folder: output, overwrite: false)
            let (stream, continuation) = AsyncStream<ConversionProgress>.makeStream()

            // Consume progress updates on the main actor.
            let progressTask = Task { @MainActor in
                for await update in stream {
                    completed = update.completed
                    currentFileName = update.currentFileName
                }
            }

            let results = await engine.run(urls: pdfs,
                                           converter: converter,
                                           writer: writer,
                                           useTitleForName: useTitleForName,
                                           progress: continuation)
            continuation.finish()
            await progressTask.value

            outcomes = results
            completed = pdfs.count
            isConverting = false
            statusMessage = summary(for: results)
        }
    }

    private func summary(for results: [ConversionOutcome]) -> String {
        let ok = results.filter(\.didSucceed).count
        let failed = results.count - ok
        if failed == 0 {
            return "Converted \(ok) file\(ok == 1 ? "" : "s")."
        }
        return "Converted \(ok) of \(results.count) — \(failed) failed."
    }

    // MARK: - Finder integration

    /// Reveal a converted file in Finder. The file lives inside the user-granted
    /// output folder, so we briefly re-acquire that folder's security scope.
    func reveal(_ url: URL) {
        withOutputAccess {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    /// Open the output folder in Finder, re-acquiring its security scope first.
    func openOutputFolder() {
        guard let folder = outputFolder else { return }
        withOutputAccess {
            NSWorkspace.shared.open(folder)
        }
    }

    /// Run `body` while holding security-scoped access to the output folder
    /// (required for a sandboxed app to hand user-selected locations to Finder).
    private func withOutputAccess(_ body: () -> Void) {
        let folder = outputFolder
        let scoped = folder?.startAccessingSecurityScopedResource() ?? false
        defer { if scoped { folder?.stopAccessingSecurityScopedResource() } }
        body()
    }
}
