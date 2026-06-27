import SwiftUI
import UniformTypeIdentifiers

/// The single main window: select inputs, choose an output folder, convert,
/// and review results.
struct ContentView: View {
    @StateObject private var model = ConversionViewModel()

    /// What the single file importer is currently selecting.
    private enum ImportMode {
        case pdfs, folder, output

        var contentTypes: [UTType] {
            switch self {
            case .pdfs: return [.pdf]
            case .folder, .output: return [.folder]
            }
        }

        var allowsMultiple: Bool {
            switch self {
            case .pdfs, .folder: return true
            case .output: return false
            }
        }
    }

    @State private var showingImporter = false
    @State private var importMode: ImportMode = .pdfs

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            inputSection
            outputSection
            optionsSection
            actionBar

            if model.isConverting {
                progressSection
            }

            if !model.outcomes.isEmpty {
                ResultsView(outcomes: model.outcomes,
                            onReveal: model.reveal,
                            onOpenFolder: model.openOutputFolder)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 580, minHeight: 540)
        // A single importer (SwiftUI only honors one .fileImporter per view);
        // `importMode` selects what it picks and where the result is routed.
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: importMode.contentTypes,
                      allowsMultipleSelection: importMode.allowsMultiple) { result in
            switch importMode {
            case .output:
                model.setOutputFolder(from: result)
            case .pdfs, .folder:
                model.addInputs(from: result)
            }
        }
    }

    private func present(_ mode: ImportMode) {
        importMode = mode
        showingImporter = true
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PDF2MD")
                .font(.largeTitle.bold())
            Text("Convert PDF files to Markdown — locally and privately.")
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        GroupBox("1 · Choose PDFs") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button("Choose PDFs…") { present(.pdfs) }
                    Button("Choose Folder…") { present(.folder) }
                    Spacer()
                    if !model.inputURLs.isEmpty {
                        Button("Clear", role: .destructive) { model.clearInputs() }
                            .disabled(model.isConverting)
                    }
                }
                Text(model.inputSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
    }

    private var outputSection: some View {
        GroupBox("2 · Choose output folder") {
            VStack(alignment: .leading, spacing: 10) {
                Button("Choose Output Folder…") { present(.output) }
                Text(model.outputSummary)
                    .font(.callout)
                    .foregroundStyle(model.outputFolder == nil ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
    }

    private var optionsSection: some View {
        GroupBox("Options") {
            VStack(alignment: .leading, spacing: 6) {
                Toggle("Name files by the document's title", isOn: $model.nameByTitle)
                Toggle("Include PDFs in subfolders", isOn: $model.includeSubfolders)
                Toggle("Insert a divider between pages", isOn: $model.insertPageSeparators)
            }
            .disabled(model.isConverting)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
        }
    }

    private var actionBar: some View {
        HStack {
            Button {
                model.startConversion()
            } label: {
                Label("Convert", systemImage: "doc.text")
                    .frame(minWidth: 120)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(!model.canConvert)

            if let message = model.statusMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(model.failureCount > 0 ? .orange : .secondary)
            }
            Spacer()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(model.completed),
                         total: Double(max(model.total, 1)))
            Text("Converting \(model.completed) of \(model.total)"
                 + (model.currentFileName.isEmpty ? "" : " — \(model.currentFileName)"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
