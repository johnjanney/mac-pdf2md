import Foundation

/// The supported LLM providers for the vision-based conversion engine.
enum LLMProvider: String, CaseIterable, Identifiable, Sendable {
    case anthropic
    case openai
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic (Claude)"
        case .openai: return "OpenAI (ChatGPT)"
        case .google: return "Google (Gemini)"
        }
    }

    /// A sensible, vision-capable default model. Editable in Settings so the
    /// app keeps working as providers release new model IDs.
    var defaultModel: String {
        switch self {
        case .anthropic: return "claude-opus-4-8"
        case .openai: return "gpt-4o"
        case .google: return "gemini-2.5-flash"
        }
    }

    /// Keychain account name under which this provider's API key is stored.
    var keychainAccount: String { "apikey.\(rawValue)" }

    /// Where the user can obtain an API key.
    var apiKeyURL: String {
        switch self {
        case .anthropic: return "https://console.anthropic.com/settings/keys"
        case .openai: return "https://platform.openai.com/api-keys"
        case .google: return "https://aistudio.google.com/apikey"
        }
    }
}

/// Errors raised by the LLM engine.
enum LLMError: LocalizedError, Sendable {
    case missingAPIKey(String)
    case http(status: Int, message: String)
    case emptyResponse(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "No API key set for \(provider). Add one in Settings."
        case .http(let status, let message):
            return "\(provider(forStatus: status)) request failed (HTTP \(status)): \(message)"
        case .emptyResponse(let provider):
            return "\(provider) returned an empty response."
        case .network(let message):
            return "Network error: \(message)"
        }
    }

    private func provider(forStatus: Int) -> String { "AI provider" }
}
