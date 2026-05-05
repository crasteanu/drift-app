import Foundation

// MARK: - Response models

struct DreamInterpretation: Codable {
    let title: String
    let emojis: [String]
    let tags: [String]
    let vividness: Int
    let snippet: String
    let reflection: ReflectionContent
    let pattern: String?
    let symbols: [SymbolContent]
    let journalPrompts: JournalPrompts
    let emotionalSignature: [String]
}

struct ReflectionContent: Codable {
    let inner: String
    let esoteric: String
}

struct SymbolContent: Codable {
    let name: String
    let emoji: String
    let category: String
    let inner: String
    let esoteric: String
}

struct JournalPrompts: Codable {
    let inner: String
    let esoteric: String
}

// MARK: - Request models

private struct CloudflareRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [Message]

    struct Message: Encodable {
        let role: String
        let content: String
    }
}

// MARK: - Service

enum ClaudeService {
    static let proxyURL = URL(string: "https://drift-api-proxy.claudiualina.workers.dev")!

    static func interpret(
        transcript: String,
        mode: String,
        previousDreams: [Dream],
        language: String
    ) async throws -> DreamInterpretation {
        let previousContext: String
        if previousDreams.isEmpty {
            previousContext = "none"
        } else {
            previousContext = previousDreams.prefix(3).map { "\"\($0.title)\": \($0.snippet)" }.joined(separator: "; ")
        }

        let userPrompt = """
        Dream transcript: "\(transcript)"
        Interpretation mode: \(mode)
        Previous dreams context: \(previousContext)
        Language: \(language)
        Return this exact JSON structure:
        {
          "title": "poetic dream title in the same language as transcript",
          "emojis": ["emoji1", "emoji2", "emoji3"],
          "tags": ["tag1", "tag2"],
          "vividness": 73,
          "snippet": "one evocative sentence summarising the dream feel",
          "reflection": {
            "inner": "psychological interpretation paragraph",
            "esoteric": "esoteric interpretation paragraph"
          },
          "pattern": "cross-dream pattern observation referencing previous dreams (null if first dream)",
          "symbols": [
            {
              "name": "symbol name",
              "emoji": "🏠",
              "category": "Spaces",
              "inner": "Jungian psychological meaning",
              "esoteric": "mythological/esoteric meaning"
            }
          ],
          "journalPrompts": {
            "inner": "psychological journal question",
            "esoteric": "esoteric journal question"
          },
          "emotionalSignature": ["emotion1", "emotion2", "emotion3", "emotion4"]
        }
        """

        let systemPrompt = "You are a dream interpreter for the Drift app. Analyze the dream transcript and return ONLY valid JSON with no other text, no markdown code fences, no explanation."

        let body = CloudflareRequest(
            model: "claude-sonnet-4-5",
            max_tokens: 4000,
            system: systemPrompt,
            messages: [.init(role: "user", content: userPrompt)]
        )

        var request = URLRequest(url: proxyURL, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ClaudeError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        // Proxy returns the Claude API response directly
        struct ClaudeAPIResponse: Decodable {
            struct Content: Decodable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }

        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        guard let text = apiResponse.content.first(where: { $0.type == "text" })?.text else {
            throw ClaudeError.emptyResponse
        }

        // Strip any accidental markdown fences
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeError.invalidJSON
        }

        do {
            return try JSONDecoder().decode(DreamInterpretation.self, from: jsonData)
        } catch {
            throw ClaudeError.invalidJSON
        }
    }
}

enum ClaudeError: LocalizedError {
    case httpError(Int)
    case emptyResponse
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .httpError(let code): return "Server returned error \(code)"
        case .emptyResponse: return "Empty response from AI"
        case .invalidJSON: return "Could not parse AI response"
        }
    }
}
