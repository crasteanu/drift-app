import SwiftUI
import SwiftData

struct ReflectionView: View {
    // New dream flow
    var interpretation: DreamInterpretation?
    var transcript: String?
    var mode: String?
    var recordingDuration: TimeInterval?
    var dreams: [Dream]?

    // Read-only existing dream
    var dream: Dream?
    var isReadOnly: Bool = false

    // Inline callbacks for non-sheet presentation
    var onRetry: (() -> Void)?
    var onFinish: (() -> Void)?

    @Query(sort: \Dream.date, order: .reverse) private var allDreams: [Dream]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var sleepRating: Int = 0
    @State private var savedDream: Dream?
    @State private var didSave = false
    @State private var showEdit = false

    private var displayMode: String { mode ?? dream?.interpretationMode ?? "both" }
    private var symbolLibrary: [(name: String, emoji: String, category: String, count: Int)] {
        let base = dreams ?? allDreams
        return PatternEngine.allSymbolLibrary(from: base)
    }

    private var isInline: Bool { onRetry != nil || onFinish != nil }

    var body: some View {
        content
            .wrapInNavigationStack(unless: isInline)
    }

    private var content: some View {
        ZStack {
            Color.driftBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                        if let interp = interpretation {
                            // New dream
                            HeroCard(
                                emojis: interp.emojis,
                                title: interp.title,
                                snippet: interp.snippet,
                                tags: interp.tags,
                                vividness: interp.vividness,
                                mode: displayMode
                            )
                            ReflectionCard(inner: interp.reflection.inner, esoteric: interp.reflection.esoteric, mode: displayMode)
                            if let pattern = interp.pattern, !pattern.isEmpty {
                                PatternCard(pattern: pattern)
                            }
                            ForEach(Array(interp.symbols.enumerated()), id: \.offset) { _, sym in
                                SymbolCard(symbol: sym, mode: displayMode)
                            }
                            JournalPromptCard(inner: interp.journalPrompts.inner, esoteric: interp.journalPrompts.esoteric, mode: displayMode)
                            EmotionalSignatureSection(emotions: interp.emotionalSignature)
                                .padding(20)
                                .background(Color.driftCard)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            if !symbolLibrary.isEmpty {
                                SymbolLibrarySection(symbols: symbolLibrary)
                                    .padding(20)
                                    .background(Color.driftCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            SleepRatingView(rating: $sleepRating)
                                .padding(20)
                                .background(Color.driftCard)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            ctaButtons

                        } else if let d = dream {
                            // Read-only
                            HeroCard(
                                emojis: d.emojis,
                                title: d.title,
                                snippet: d.snippet,
                                tags: d.tags,
                                vividness: d.vividness,
                                mode: d.interpretationMode
                            )
                            ReflectionCard(inner: d.reflectionInner, esoteric: d.reflectionEsoteric, mode: d.interpretationMode)
                            if let pattern = d.pattern, !pattern.isEmpty {
                                PatternCard(pattern: pattern)
                            }
                            ForEach(Array(d.symbols.enumerated()), id: \.offset) { _, sym in
                                SymbolCard(symbol: SymbolContent(name: sym.name, emoji: sym.emoji, category: sym.category, inner: sym.inner, esoteric: sym.esoteric), mode: d.interpretationMode)
                            }
                            JournalPromptCard(inner: d.journalPromptInner, esoteric: d.journalPromptEsoteric, mode: d.interpretationMode)
                            EmotionalSignatureSection(emotions: d.emotionalSignature)
                                .padding(20)
                                .background(Color.driftCard)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            if let r = d.sleepRating {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sleep Rating")
                                        .font(.outfit(14, weight: .semibold))
                                        .foregroundColor(.white)
                                    HStack {
                                        ForEach(1...5, id: \.self) { s in
                                            Image(systemName: s <= r ? "star.fill" : "star")
                                                .foregroundColor(s <= r ? .driftAmber : .white.opacity(0.3))
                                        }
                                    }
                                }
                                .padding(20)
                                .background(Color.driftCard)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }

                    Color.clear.frame(height: 40)
                }
                .padding(16)
            }
        }
            .sheet(isPresented: $showEdit) {
                if let d = dream {
                    DreamEditView(dream: d)
                }
            }
            .modifier(NavigationBarModifier(isInline: isInline, isReadOnly: isReadOnly, onEdit: { showEdit = true }, onDismiss: { dismiss() }))
            .onAppear {
                if !isReadOnly, let interp = interpretation, !didSave {
                    saveDream(from: interp)
                    didSave = true
                }
            }
    }

    @ViewBuilder
    private var ctaButtons: some View {
        HStack(spacing: 12) {
            Button {
                if let retry = onRetry { retry() } else { dismiss() }
            } label: {
                Text("↺ Try again")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.driftPurple)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.driftPurple.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.driftPurple, lineWidth: 1))
            }

            Button {
                if let saved = savedDream {
                    saved.sleepRating = sleepRating > 0 ? sleepRating : nil
                }
                if let finish = onFinish { finish() } else { dismiss() }
            } label: {
                Text("All dreams →")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.driftPurple)
                    .clipShape(Capsule())
            }
        }
    }

    private func saveDream(from interp: DreamInterpretation) {
        let symbols = interp.symbols.map { s in
            DreamSymbol(name: s.name, emoji: s.emoji, category: s.category, inner: s.inner, esoteric: s.esoteric)
        }
        let d = Dream(
            transcript: transcript ?? "",
            title: interp.title,
            emojis: interp.emojis,
            tags: interp.tags,
            vividness: interp.vividness,
            snippet: interp.snippet,
            reflectionInner: interp.reflection.inner,
            reflectionEsoteric: interp.reflection.esoteric,
            pattern: interp.pattern,
            symbols: symbols,
            journalPromptInner: interp.journalPrompts.inner,
            journalPromptEsoteric: interp.journalPrompts.esoteric,
            emotionalSignature: interp.emotionalSignature,
            interpretationMode: mode ?? "both",
            recordingDuration: recordingDuration ?? 0
        )
        context.insert(d)
        savedDream = d
    }
}

private extension View {
    @ViewBuilder
    func wrapInNavigationStack(unless skip: Bool) -> some View {
        if skip {
            self
        } else {
            NavigationStack { self }
        }
    }
}

// Only applies navigation bar configuration when the view owns its own NavigationStack.
// When inline inside RecordView's NavigationStack, we skip these to avoid the
// "top item belongs to a different navigation bar" layout conflict.
private struct NavigationBarModifier: ViewModifier {
    let isInline: Bool
    let isReadOnly: Bool
    let onEdit: () -> Void
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        if isInline {
            content
        } else {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if isReadOnly {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done", action: onDismiss)
                                .foregroundColor(.driftPurple)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: onEdit) {
                                Label("Edit", systemImage: "pencil")
                                    .font(.outfit(14, weight: .medium))
                                    .foregroundColor(.driftTeal)
                            }
                        }
                    } else {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: onDismiss) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Record")
                                }
                                .foregroundColor(.driftPurple)
                            }
                        }
                    }
                }
        }
    }
}
