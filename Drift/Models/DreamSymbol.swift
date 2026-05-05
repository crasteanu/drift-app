import Foundation
import SwiftData

@Model
final class DreamSymbol {
    var name: String
    var emoji: String
    var category: String
    var inner: String
    var esoteric: String
    var occurrenceCount: Int

    init(name: String, emoji: String, category: String, inner: String, esoteric: String, occurrenceCount: Int = 1) {
        self.name = name
        self.emoji = emoji
        self.category = category
        self.inner = inner
        self.esoteric = esoteric
        self.occurrenceCount = occurrenceCount
    }
}
