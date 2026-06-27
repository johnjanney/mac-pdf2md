import Foundation

/// Sends a rendered page image to a provider's vision model and returns the
/// Markdown transcription. Uses raw HTTPS (URLSession) since there is no
/// official Swift SDK for these providers.
struct LLMClient: Sendable {

    /// Instruction sent with every page.
    static let prompt = """
    You are a precise document-to-Markdown converter. Convert the page image \
    into clean GitHub-Flavored Markdown that preserves the document's visual \
    structure and intent.

    Rules:
    - Use #/##/### headings that match the visual hierarchy.
    - Preserve lists (bulleted and numbered), bold/italic emphasis, and inline code.
    - Reproduce tables as GitHub Markdown tables.
    - For charts, graphs, or figures, insert a concise description in a \
    > blockquote, prefixed with "Figure:".
    - Transcribe text faithfully; do not summarize or omit content.
    - Do not wrap the whole output in a code fence and do not add commentary.
    - Output ONLY the Markdown for this page.
    """

    func convertImage(provider: LLMProvider,
                      model: String,
                      apiKey: String,
                      imageBase64: String) async throws -> String {
        let request = try makeRequest(provider: provider, model: model, apiKey: apiKey, imageBase64: imageBase64)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw LLMError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.network("No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw LLMError.http(status: http.statusCode,
                                message: Self.extractErrorMessage(data) ?? "Request failed")
        }
        guard let markdown = Self.extractMarkdown(provider: provider, data: data),
              !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let detail = Self.diagnostic(provider: provider, data: data)
            throw LLMError.emptyResponse(provider.displayName + (detail.map { " — \($0)" } ?? ""))
        }
        return markdown
    }

    // MARK: - Request building

    private func makeRequest(provider: LLMProvider,
                             model: String,
                             apiKey: String,
                             imageBase64: String) throws -> URLRequest {
        let maxTokens = 16000
        switch provider {
        case .anthropic:
            var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let body: [String: Any] = [
                "model": model,
                "max_tokens": maxTokens,
                "system": Self.prompt,
                "messages": [[
                    "role": "user",
                    "content": [
                        ["type": "image",
                         "source": ["type": "base64", "media_type": "image/png", "data": imageBase64]],
                        ["type": "text", "text": "Convert this page to Markdown."],
                    ],
                ]],
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            return req

        case .openai:
            var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let body: [String: Any] = [
                "model": model,
                "max_tokens": maxTokens,
                "messages": [
                    ["role": "system", "content": Self.prompt],
                    ["role": "user", "content": [
                        ["type": "text", "text": "Convert this page to Markdown."],
                        ["type": "image_url",
                         "image_url": ["url": "data:image/png;base64,\(imageBase64)"]],
                    ]],
                ],
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            return req

        case .google:
            let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
            var req = URLRequest(url: URL(string: urlString)!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            let body: [String: Any] = [
                "system_instruction": ["parts": [["text": Self.prompt]]],
                "contents": [[
                    "parts": [
                        ["text": "Convert this page to Markdown."],
                        ["inline_data": ["mime_type": "image/png", "data": imageBase64]],
                    ],
                ]],
                // Disable "thinking" so the whole token budget goes to the
                // transcription — Gemini 2.5 models otherwise can spend it all
                // thinking and return no text.
                "generationConfig": [
                    "maxOutputTokens": maxTokens,
                    "thinkingConfig": ["thinkingBudget": 0],
                ],
            ]
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            return req
        }
    }

    // MARK: - Response parsing

    static func extractMarkdown(provider: LLMProvider, data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        switch provider {
        case .anthropic:
            // { "content": [ { "type": "text", "text": "..." }, ... ] }
            let blocks = json["content"] as? [[String: Any]] ?? []
            let text = blocks.compactMap { ($0["type"] as? String) == "text" ? $0["text"] as? String : nil }
                .joined()
            return text.isEmpty ? nil : text

        case .openai:
            // { "choices": [ { "message": { "content": "..." } } ] }
            let choices = json["choices"] as? [[String: Any]] ?? []
            return (choices.first?["message"] as? [String: Any])?["content"] as? String

        case .google:
            // { "candidates": [ { "content": { "parts": [ { "text": "..." } ] } } ] }
            let candidates = json["candidates"] as? [[String: Any]] ?? []
            let content = candidates.first?["content"] as? [String: Any]
            let parts = content?["parts"] as? [[String: Any]] ?? []
            let text = parts.compactMap { $0["text"] as? String }.joined()
            return text.isEmpty ? nil : text
        }
    }

    /// Pull a human-readable message out of a provider error body.
    static func extractErrorMessage(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        if let message = json["message"] as? String {
            return message
        }
        return nil
    }

    /// When a 200 response yields no text, surface why (finish reason, safety
    /// block, etc.) so the failure is diagnosable rather than just "empty".
    static func diagnostic(provider: LLMProvider, data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        switch provider {
        case .google:
            if let feedback = json["promptFeedback"] as? [String: Any],
               let blockReason = feedback["blockReason"] as? String {
                return "blocked: \(blockReason)"
            }
            if let candidates = json["candidates"] as? [[String: Any]],
               let reason = candidates.first?["finishReason"] as? String {
                return reason == "MAX_TOKENS"
                    ? "hit the output limit (try a smaller page or different model)"
                    : "finish reason: \(reason)"
            }
        case .anthropic:
            if let reason = json["stop_reason"] as? String { return "stop reason: \(reason)" }
        case .openai:
            if let choices = json["choices"] as? [[String: Any]],
               let reason = choices.first?["finish_reason"] as? String {
                return "finish reason: \(reason)"
            }
        }
        return nil
    }
}
