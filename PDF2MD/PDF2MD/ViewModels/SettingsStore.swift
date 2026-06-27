import Foundation
import SwiftUI

/// Holds the conversion-engine settings: which engine to use, the selected LLM
/// provider, per-provider model IDs, and the API keys.
///
/// Non-secret preferences persist in UserDefaults; API keys persist in the
/// Keychain. Key drafts are held in memory and written to the Keychain when
/// `persistKeys()` is called (from the Settings UI).
@MainActor
final class SettingsStore: ObservableObject {
    enum EngineKind: String { case local, llm }

    @Published var engine: EngineKind {
        didSet { defaults.set(engine.rawValue, forKey: "engine") }
    }
    @Published var provider: LLMProvider {
        didSet { defaults.set(provider.rawValue, forKey: "provider") }
    }

    // Per-provider model IDs (editable so the app survives provider model churn).
    @Published var anthropicModel: String { didSet { defaults.set(anthropicModel, forKey: "model.anthropic") } }
    @Published var openAIModel: String { didSet { defaults.set(openAIModel, forKey: "model.openai") } }
    @Published var googleModel: String { didSet { defaults.set(googleModel, forKey: "model.google") } }

    // API key drafts — loaded from Keychain at init, written back via persistKeys().
    @Published var anthropicKey: String
    @Published var openAIKey: String
    @Published var googleKey: String

    private let defaults = UserDefaults.standard

    init() {
        defaults.register(defaults: [:])
        engine = EngineKind(rawValue: defaults.string(forKey: "engine") ?? "") ?? .local
        provider = LLMProvider(rawValue: defaults.string(forKey: "provider") ?? "") ?? .anthropic
        anthropicModel = defaults.string(forKey: "model.anthropic") ?? LLMProvider.anthropic.defaultModel
        openAIModel = defaults.string(forKey: "model.openai") ?? LLMProvider.openai.defaultModel
        googleModel = defaults.string(forKey: "model.google") ?? LLMProvider.google.defaultModel
        anthropicKey = Keychain.get(LLMProvider.anthropic.keychainAccount) ?? ""
        openAIKey = Keychain.get(LLMProvider.openai.keychainAccount) ?? ""
        googleKey = Keychain.get(LLMProvider.google.keychainAccount) ?? ""
    }

    // MARK: - Accessors

    func model(for provider: LLMProvider) -> String {
        switch provider {
        case .anthropic: return anthropicModel.trimmingCharacters(in: .whitespacesAndNewlines)
        case .openai: return openAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
        case .google: return googleModel.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func key(for provider: LLMProvider) -> String {
        switch provider {
        case .anthropic: return anthropicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .openai: return openAIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .google: return googleKey.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var selectedProviderHasKey: Bool { !key(for: provider).isEmpty }

    // MARK: - Persistence

    /// Write the current key drafts to the Keychain (empty values are removed).
    func persistKeys() {
        save(anthropicKey, for: .anthropic)
        save(openAIKey, for: .openai)
        save(googleKey, for: .google)
    }

    private func save(_ key: String, for provider: LLMProvider) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Keychain.delete(provider.keychainAccount)
        } else {
            Keychain.set(trimmed, for: provider.keychainAccount)
        }
    }
}
