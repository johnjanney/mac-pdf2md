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

    /// How the AI engine processes a PDF.
    /// - `vision`: AI reads the page images (pre-process).
    /// - `cleanup`: local text extraction, then AI tidies it (post-process).
    enum AIMode: String { case vision, cleanup }

    @Published var engine: EngineKind {
        didSet { defaults.set(engine.rawValue, forKey: "engine") }
    }
    @Published var aiMode: AIMode {
        didSet { defaults.set(aiMode.rawValue, forKey: "aiMode") }
    }
    @Published var provider: LLMProvider {
        didSet { defaults.set(provider.rawValue, forKey: "provider") }
    }

    // Per-provider model IDs (editable so the app survives provider model churn).
    @Published var anthropicModel: String { didSet { defaults.set(anthropicModel, forKey: "model.anthropic") } }
    @Published var openAIModel: String { didSet { defaults.set(openAIModel, forKey: "model.openai") } }
    @Published var googleModel: String { didSet { defaults.set(googleModel, forKey: "model.google") } }
    @Published var deepseekModel: String { didSet { defaults.set(deepseekModel, forKey: "model.deepseek") } }

    // API key drafts — loaded from Keychain at init, written back via persistKeys().
    @Published var anthropicKey: String
    @Published var openAIKey: String
    @Published var googleKey: String
    @Published var deepseekKey: String

    private let defaults = UserDefaults.standard

    init() {
        defaults.register(defaults: [:])
        engine = EngineKind(rawValue: defaults.string(forKey: "engine") ?? "") ?? .local
        aiMode = AIMode(rawValue: defaults.string(forKey: "aiMode") ?? "") ?? .vision
        provider = LLMProvider(rawValue: defaults.string(forKey: "provider") ?? "") ?? .anthropic
        anthropicModel = defaults.string(forKey: "model.anthropic") ?? LLMProvider.anthropic.defaultModel
        openAIModel = defaults.string(forKey: "model.openai") ?? LLMProvider.openai.defaultModel
        googleModel = defaults.string(forKey: "model.google") ?? LLMProvider.google.defaultModel
        deepseekModel = defaults.string(forKey: "model.deepseek") ?? LLMProvider.deepseek.defaultModel
        anthropicKey = Keychain.get(LLMProvider.anthropic.keychainAccount) ?? ""
        openAIKey = Keychain.get(LLMProvider.openai.keychainAccount) ?? ""
        googleKey = Keychain.get(LLMProvider.google.keychainAccount) ?? ""
        deepseekKey = Keychain.get(LLMProvider.deepseek.keychainAccount) ?? ""
    }

    // MARK: - Accessors

    func model(for provider: LLMProvider) -> String {
        let raw: String
        switch provider {
        case .anthropic: raw = anthropicModel
        case .openai: raw = openAIModel
        case .google: raw = googleModel
        case .deepseek: raw = deepseekModel
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func key(for provider: LLMProvider) -> String {
        let raw: String
        switch provider {
        case .anthropic: raw = anthropicKey
        case .openai: raw = openAIKey
        case .google: raw = googleKey
        case .deepseek: raw = deepseekKey
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var selectedProviderHasKey: Bool { !key(for: provider).isEmpty }

    // MARK: - Persistence

    /// Write the current key drafts to the Keychain (empty values are removed).
    func persistKeys() {
        save(anthropicKey, for: .anthropic)
        save(openAIKey, for: .openai)
        save(googleKey, for: .google)
        save(deepseekKey, for: .deepseek)
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
