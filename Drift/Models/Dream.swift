import Foundation
import SwiftData

@Model
final class Dream {
    var id: UUID
    var date: Date
    var transcript: String
    var title: String
    var emojis: [String]
    var tags: [String]
    var vividness: Int
    var snippet: String
    var reflectionInner: String
    var reflectionEsoteric: String
    var pattern: String?
    @Relationship(deleteRule: .cascade) var symbols: [DreamSymbol]
    var journalPromptInner: String
    var journalPromptEsoteric: String
    var emotionalSignature: [String]
    var sleepRating: Int?
    var interpretationMode: String // "inner", "esoteric", "both"
    var recordingDuration: TimeInterval
    var isStarred: Bool

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        transcript: String,
        title: String,
        emojis: [String] = [],
        tags: [String] = [],
        vividness: Int = 50,
        snippet: String = "",
        reflectionInner: String = "",
        reflectionEsoteric: String = "",
        pattern: String? = nil,
        symbols: [DreamSymbol] = [],
        journalPromptInner: String = "",
        journalPromptEsoteric: String = "",
        emotionalSignature: [String] = [],
        sleepRating: Int? = nil,
        interpretationMode: String = "both",
        recordingDuration: TimeInterval = 0,
        isStarred: Bool = false
    ) {
        self.id = id
        self.date = date
        self.transcript = transcript
        self.title = title
        self.emojis = emojis
        self.tags = tags
        self.vividness = vividness
        self.snippet = snippet
        self.reflectionInner = reflectionInner
        self.reflectionEsoteric = reflectionEsoteric
        self.pattern = pattern
        self.symbols = symbols
        self.journalPromptInner = journalPromptInner
        self.journalPromptEsoteric = journalPromptEsoteric
        self.emotionalSignature = emotionalSignature
        self.sleepRating = sleepRating
        self.interpretationMode = interpretationMode
        self.recordingDuration = recordingDuration
        self.isStarred = isStarred
    }

    var formattedDate: String { Dream.formattedDateFormatter.string(from: date) }
    var shortDate: String { Dream.shortDateFormatter.string(from: date) }

    private static let formattedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd. MMM yyyy"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd. MMM"
        return f
    }()

    var emojiString: String { emojis.joined() }
}
