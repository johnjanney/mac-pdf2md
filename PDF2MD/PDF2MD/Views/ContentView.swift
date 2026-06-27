import SwiftUI
import UniformTypeIdentifiers

/// The single main window: select inputs, choose an output folder, convert,
/// and review results.
struct ContentView: View {
    @StateObject private var model = ConversionViewModel()

    @State private var showingPDFImporter = false
    @State private var showingFolderImporter = false
    @State private var showingOutputImporter = false

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
        .fileImporter(isPresented: $showingPDFImporter,
                      allowedContentTypes: [.pdf],
                      allowsMultipleSelection: true) { model.addInputs(from: $0) }
        .fileImporter(isPresented: $showingFolderImporter,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: true) { model.addInputs(from: $0) }
        .fileImporter(isPresented: $showingOutputImporter,
                      allowedContentTypes: [.folder],
                      allowsMultipleSelection: false) { model.setOutputFolder(from: $0) }
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
                    Button("Choose PDFs…") { showingPDFImporter = true }
                    Button("Choose Folder…") { showingFolderImporter = true }
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
                Button("Choose Output Folder…") { showingOutputImporter = true }
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
