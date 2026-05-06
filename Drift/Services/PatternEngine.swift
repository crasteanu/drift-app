import Foundation

struct PatternInsight {
    let title: String
    let description: String
    let icon: String
}

struct EmotionalDataPoint {
    let month: Int
    let tension: Double
    let calm: Double
    let vivid: Double
    let uncertain: Double
}

enum PatternEngine {

    static func insights(from dreams: [Dream]) -> [PatternInsight] {
        guard dreams.count >= 5 else { return [] }
        var insights: [PatternInsight] = []

        // Recurring symbols — count distinct dreams containing each symbol
        var symbolDreamCount: [String: Int] = [:]
        for dream in dreams {
            let uniqueNamesInDream = Set(dream.symbols.map { $0.name.lowercased() })
            for name in uniqueNamesInDream {
                symbolDreamCount[name, default: 0] += 1
            }
        }
        if let top = symbolDreamCount.max(by: { $0.value < $1.value }), top.value >= 2 {
            insights.append(.init(
                title: "Recurring Symbol",
                description: "\"\(top.key.capitalized)\" appears in \(top.value) of your dreams.",
                icon: "repeat"
            ))
        }

        // Average vividness trend
        let recent = dreams.suffix(5).map { Double($0.vividness) }
        let older = dreams.prefix(max(1, dreams.count - 5)).map { Double($0.vividness) }
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.isEmpty ? recentAvg : older.reduce(0, +) / Double(older.count)
        if recentAvg > olderAvg + 5 {
            insights.append(.init(
                title: "Rising Vividness",
                description: "Your recent dreams are more vivid than earlier ones.",
                icon: "chart.line.uptrend.xyaxis"
            ))
        } else if recentAvg < olderAvg - 5 {
            insights.append(.init(
                title: "Fading Vividness",
                description: "Your dreams have been less vivid lately.",
                icon: "chart.line.downtrend.xyaxis"
            ))
        }

        // Dominant emotion
        let allEmotions = dreams.flatMap { $0.emotionalSignature.map { $0.lowercased() } }
        let emotionFreq = Dictionary(grouping: allEmotions, by: { $0 }).mapValues { $0.count }
        if let topEmotion = emotionFreq.max(by: { $0.value < $1.value }) {
            insights.append(.init(
                title: "Dominant Emotion",
                description: "\"\(topEmotion.key.capitalized)\" surfaces most often across your dreamscape.",
                icon: "heart.fill"
            ))
        }

        // Most active dream month
        let calendar = Calendar.current
        let monthFreq = Dictionary(grouping: dreams, by: { calendar.component(.month, from: $0.date) })
            .mapValues { $0.count }
        if let busiest = monthFreq.max(by: { $0.value < $1.value }) {
            let monthName = Calendar.current.standaloneMonthSymbols[busiest.key - 1]
            insights.append(.init(
                title: "Most Active Month",
                description: "You recorded the most dreams in \(monthName).",
                icon: "calendar"
            ))
        }

        return insights
    }

    static func emotionalArc(from dreams: [Dream]) -> [EmotionalDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dreams, by: { calendar.component(.month, from: $0.date) })
        var points: [EmotionalDataPoint] = []

        for month in 1...12 {
            let monthDreams = grouped[month] ?? []
            if monthDreams.isEmpty {
                points.append(.init(month: month, tension: 0, calm: 0, vivid: 0, uncertain: 0))
                continue
            }
            func score(_ words: [String]) -> Double {
                let lower = Set(words.map { $0.lowercased() })
                let matched = monthDreams.filter { d in
                    d.emotionalSignature.contains { lower.contains($0.lowercased()) }
                }.count
                return Double(matched) / Double(monthDreams.count)
            }
            let avgVividness = Double(monthDreams.map { $0.vividness }.reduce(0, +)) / Double(monthDreams.count) / 100.0
            points.append(.init(
                month: month,
                tension: score(["tension", "anxiety", "anxious", "fear", "afraid", "stress", "stressed"]),
                calm: score(["calm", "peace", "tranquil", "peaceful", "serene", "relaxed"]),
                vivid: avgVividness,
                uncertain: score(["uncertain", "confused", "confusion", "lost", "uncertainty", "unsure"])
            ))
        }
        return points
    }

    static func topSymbols(from dreams: [Dream], top n: Int = 5) -> [(symbol: String, emoji: String, count: Int)] {
        var symbolMap: [String: (emoji: String, count: Int)] = [:]
        for dream in dreams {
            for s in dream.symbols {
                let key = s.name.lowercased()
                if let existing = symbolMap[key] {
                    symbolMap[key] = (existing.emoji, existing.count + 1)
                } else {
                    symbolMap[key] = (s.emoji, 1)
                }
            }
        }
        return symbolMap
            .sorted { $0.value.count > $1.value.count }
            .prefix(n)
            .map { (symbol: $0.key.capitalized, emoji: $0.value.emoji, count: $0.value.count) }
    }

    static func allSymbolLibrary(from dreams: [Dream]) -> [(name: String, emoji: String, category: String, count: Int)] {
        var map: [String: (emoji: String, category: String, count: Int)] = [:]
        for dream in dreams {
            for s in dream.symbols {
                let key = s.name.lowercased()
                if let e = map[key] {
                    map[key] = (e.emoji, e.category, e.count + 1)
                } else {
                    map[key] = (s.emoji, s.category, 1)
                }
            }
        }
        return map
            .sorted { $0.value.count > $1.value.count }
            .map { (name: $0.key.capitalized, emoji: $0.value.emoji, category: $0.value.category, count: $0.value.count) }
    }

    static func streak(from dreams: [Dream]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dreamDays = Set(dreams.map { calendar.startOfDay(for: $0.date) })
        // Start from today if recorded, otherwise from yesterday (streak shouldn't break every morning)
        var current = dreamDays.contains(today) ? today : yesterday
        var count = 0
        while dreamDays.contains(current) {
            count += 1
            current = calendar.date(byAdding: .day, value: -1, to: current)!
        }
        return count
    }
}
