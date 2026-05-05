import SwiftUI

// MARK: - Hero Card

struct HeroCard: View {
    let emojis: [String]
    let title: String
    let snippet: String
    let tags: [String]
    let vividness: Int
    let mode: String

    var body: some View {
        VStack(spacing: 16) {
            // Teal accent bar at top
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient.driftTealPurple)
                .frame(height: 3)
                .frame(maxWidth: .infinity)

            Text(emojis.prefix(3).joined())
                .font(.system(size: 44))

            Text(title)
                .font(.cormorant(30, weight: .bold, italic: true))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(snippet)
                .font(.cormorant(17, italic: true))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            TagChipRow(tags: tags)
                .frame(maxWidth: .infinity)

            Divider().background(Color.white.opacity(0.08))

            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("Vividness ")
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(vividness)")
                        .font(.cormorant(28, weight: .bold))
                        .foregroundColor(.driftCoral)
                    Text(" / 100")
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.35))
                }
                Spacer()
                modeBadge
            }
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var modeBadge: some View {
        let (icon, label): (String, String) = {
            switch mode {
            case "inner":    return ("🧠", "Inner")
            case "esoteric": return ("🔮", "Esoteric")
            default:         return ("✨", "Both")
            }
        }()
        return Text("\(icon) \(label)")
            .font(.outfit(12, weight: .medium))
            .foregroundColor(.driftTeal)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.driftTeal.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - Reflection Card

struct ReflectionCard: View {
    let inner: String
    let esoteric: String
    let mode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🔮")
                Text("Reflection")
                    .font(.outfit(15, weight: .semibold))
                    .foregroundColor(.driftTeal)
            }

            if mode == "inner" || mode == "both" {
                interpretRow(icon: "🧠", text: inner)
            }
            if mode == "esoteric" || mode == "both" {
                interpretRow(icon: "🔮", text: esoteric)
            }
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func interpretRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 16))
            Text(text)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.driftTeal)
                Text("Pattern")
                    .font(.outfit(15, weight: .semibold))
                    .foregroundColor(.driftTeal)
            }

            Text(pattern)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Symbol Card

struct SymbolCard: View {
    let symbol: SymbolContent
    let mode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(symbol.emoji)
                    .font(.system(size: 20))
                Text("Symbol · \(symbol.name)")
                    .font(.outfit(15, weight: .semibold))
                    .foregroundColor(.driftAmber)
            }

            if mode == "inner" || mode == "both" {
                interpretRow(icon: "🧠", text: symbol.inner)
            }
            if mode == "esoteric" || mode == "both" {
                interpretRow(icon: "🔮", text: symbol.esoteric)
            }
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func interpretRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 15))
            Text(text)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Journal Prompt Card

struct JournalPromptCard: View {
    let inner: String
    let esoteric: String
    let mode: String

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.driftAmber)
                .frame(width: 3)
                .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.driftAmber)
                    Text("Journal Prompt")
                        .font(.outfit(15, weight: .semibold))
                        .foregroundColor(.driftAmber)
                }

                if mode == "inner" || mode == "both" {
                    promptRow(icon: "🧠", text: inner)
                }
                if mode == "esoteric" || mode == "both" {
                    promptRow(icon: "🔮", text: esoteric)
                }
            }
            .padding(20)
        }
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func promptRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 15))
            Text(text)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.8))
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Emotional Signature

struct EmotionalSignatureSection: View {
    let emotions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emotional Signature")
                .font(.outfit(15, weight: .semibold))
                .foregroundColor(.white)

            FlowLayout(spacing: 8) {
                ForEach(Array(emotions.enumerated()), id: \.offset) { i, emotion in
                    Text(emotion)
                        .font(.outfit(12, weight: .medium))
                        .foregroundColor(tagColor(for: i))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tagColor(for: i).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Symbol Library

struct SymbolLibrarySection: View {
    let symbols: [(name: String, emoji: String, category: String, count: Int)]

    let columns = [GridItem(.adaptive(minimum: 80), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Symbol Library")
                .font(.outfit(15, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(symbols, id: \.name) { sym in
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            Text(sym.emoji)
                                .font(.system(size: 28))
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            if sym.count > 1 {
                                Text("\(sym.count)")
                                    .font(.outfit(9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.driftPurple)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                        Text(sym.name)
                            .font(.outfit(11))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - Sleep Rating

struct SleepRatingView: View {
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How was your sleep?")
                .font(.outfit(15, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundColor(star <= rating ? .driftAmber : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
