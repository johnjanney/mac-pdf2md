import Foundation

/// Live progress for an in-flight conversion run.
struct ConversionProgress: Sendable {
    let completed: Int
    let total: Int
    let currentFileName: String
}

/// The outcome of converting one file.
struct ConversionOutcome: Identifiable, Sendable {
    enum Status: Sendable {
        case success(outputURL: URL)
        case failure(message: String)
    }

    let id = UUID()
    let sourceName: String
    let status: Status

    var didSucceed: Bool {
        if case .success = status { return true }
        return false
    }
}

/// Runs a batch of single-file conversions off the main thread.
///
/// Implemented as an `actor` so the (CPU-bound) PDFKit work executes on a
/// background executor, keeping the UI responsive. Progress is reported through
/// an `AsyncStream` continuation; a single failing file never aborts the run.
actor BatchEngine {
    func run(urls: [URL],
             converter: PDFConverter,
             writer: OutputWriter,
             progress: AsyncStream<ConversionProgress>.Continuation) -> [ConversionOutcome] {
        var outcomes: [ConversionOutcome] = []
        let total = urls.count

        for (index, url) in urls.enumerated() {
            progress.yield(ConversionProgress(completed: index,
                                              total: total,
                                              currentFileName: url.lastPathComponent))
            let baseName = url.deletingPathExtension().lastPathComponent
            do {
                let document = try converter.convert(pdfAt: url)
                let outputURL = try writer.write(document, sourceName: baseName)
                outcomes.append(ConversionOutcome(sourceName: url.lastPathComponent,
                                                  status: .success(outputURL: outputURL)))
            } catch {
                let message = (error as? ConversionError)?.errorDescription ?? error.localizedDescription
                outcomes.append(ConversionOutcome(sourceName: url.lastPathComponent,
                                                  status: .failure(message: message)))
            }
        }

        progress.yield(ConversionProgress(completed: total, total: total, currentFileName: ""))
        return outcomes
    }
}
