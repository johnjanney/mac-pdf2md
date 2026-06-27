import SwiftUI
import AppKit

/// The Settings window: choose the conversion engine and manage API keys.
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Section("Conversion engine") {
                Picker("Engine", selection: $settings.engine) {
                    Text("Local — fast, offline, free").tag(SettingsStore.EngineKind.local)
                    Text("AI — preserves formatting (tables, charts)").tag(SettingsStore.EngineKind.llm)
                }
                .pickerStyle(.radioGroup)

                if settings.engine == .llm {
                    Picker("Provider", selection: $settings.provider) {
                        ForEach(LLMProvider.allCases) { Text($0.displayName).tag($0) }
                    }
                }
            }

            Section("API keys") {
                providerRow(.anthropic, key: $settings.anthropicKey, model: $settings.anthropicModel)
                providerRow(.openai, key: $settings.openAIKey, model: $settings.openAIModel)
                providerRow(.google, key: $settings.googleKey, model: $settings.googleModel)

                HStack {
                    Spacer()
                    Button("Save Keys") {
                        settings.persistKeys()
                        // Close the Settings window after saving.
                        NSApp.keyWindow?.performClose(nil)
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            Section {
                Label("AI conversion sends each page image to the selected provider. "
                      + "The local engine stays fully offline. Keys are stored in your macOS Keychain.",
                      systemImage: "lock.shield")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 460)
        .onDisappear { settings.persistKeys() }
    }

    @ViewBuilder
    private func providerRow(_ provider: LLMProvider,
                             key: Binding<String>,
                             model: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(provider.displayName).font(.headline)
                Spacer()
                Link("Get key", destination: URL(string: provider.apiKeyURL)!)
                    .font(.caption)
            }
            SecureField("API key", text: key)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 6) {
                Text("Model:").foregroundStyle(.secondary)
                TextField(provider.defaultModel, text: model)
                    .textFieldStyle(.roundedBorder)
            }
            .font(.callout)
        }
        .padding(.vertical, 4)
    }
}
