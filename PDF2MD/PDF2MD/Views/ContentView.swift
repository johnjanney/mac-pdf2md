import SwiftUI
import UniformTypeIdentifiers

/// The single main window: select inputs, choose an output folder, convert,
/// and review results.
struct ContentView: View {
    @StateObject private var model = ConversionViewModel()
    @EnvironmentObject private var settings: SettingsStore

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
            engineSection
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

    /// Build the conversion engine from the current settings.
    /// Returns nil if the AI engine is selected but its API key is missing.
    private func makeConverter() -> PDFConverter? {
        switch settings.engine {
        case .local:
            return PDFKitConverter(insertPageSeparators: model.insertPageSeparators)
        case .llm:
            let key = settings.key(for: settings.provider)
            guard !key.isEmpty else { return nil }
            return LLMConverter(provider: settings.provider,
                                model: settings.model(for: settings.provider),
                                apiKey: key,
                                insertPageSeparators: model.insertPageSeparators)
        }
    }

    private func startConversion() {
        guard let converter = makeConverter() else {
            model.statusMessage = "Add a \(settings.provider.displayName) API key in Settings to use the AI engine."
            return
        }
        model.startConversion(converter: converter)
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

    private var engineSection: some View {
        GroupBox("Conversion engine") {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Engine", selection: $settings.engine) {
                    Text("Local — fast, offline, free").tag(SettingsStore.EngineKind.local)
                    Text("AI — preserves formatting (tables, charts)").tag(SettingsStore.EngineKind.llm)
                }
                .pickerStyle(.radioGroup)
                .disabled(model.isConverting)

                if settings.engine == .llm {
                    HStack(spacing: 8) {
                        Text("Provider:").foregroundStyle(.secondary)
                        Picker("Provider", selection: $settings.provider) {
                            ForEach(LLMProvider.allCases) { Text($0.displayName).tag($0) }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 220)
                        SettingsLink { Text("Settings…") }
                    }
                    .disabled(model.isConverting)

                    if !settings.provider.supportsVision {
                        Label("\(settings.provider.displayName)'s default model is text-only and "
                              + "can't read page images, so conversions will likely fail. Use Claude, "
                              + "OpenAI, or Gemini, or set a vision-capable model in Settings.",
                              systemImage: "eye.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    if settings.selectedProviderHasKey {
                        Text("Pages are sent to \(settings.provider.displayName) "
                             + "(model: \(settings.model(for: settings.provider))).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("No API key set for \(settings.provider.displayName). Add one in Settings.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
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
                startConversion()
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
        .environmentObject(SettingsStore())
}
