import SwiftUI
import SwiftData

struct DreamEditView: View {
    let dream: Dream
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dream.date, order: .reverse) private var allDreams: [Dream]
    @AppStorage("whisperLanguage") private var language = "ro"
    @Environment(StoreService.self) private var storeService
    @AppStorage("interpretationCount") private var interpretationCount: Int = 0
    @State private var showPaywall = false

    @State private var transcript: String = ""
    @State private var mode: String = "both"
    @State private var isInterpreting = false
    @State private var pendingInterpretation: DreamInterpretation? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()

                if isInterpreting {
                    LoadingView()
                        .transition(.opacity)
                } else if let interp = pendingInterpretation {
                    previewView(interp)
                        .transition(.opacity)
                } else {
                    editingView
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isInterpreting)
            .animation(.easeInOut(duration: 0.35), value: pendingInterpretation == nil)
            .navigationTitle("Edit Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
                if !isInterpreting && pendingInterpretation == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") { saveOnly() }
                            .font(.outfit(15, weight: .semibold))
                            .foregroundColor(.driftPurple)
                    }
                }
            }
        }
        .onAppear {
            transcript = dream.transcript
            mode = dream.interpretationMode
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .interpretationLimit)
        }
    }

    // MARK: - Editing view

    private var editingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mode selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interpretation style")
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.4))

                    ModePickerView(selected: $mode)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.driftCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Transcript editor
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dream transcript")
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.4))

                    ZStack(alignment: .topLeading) {
                        if transcript.isEmpty {
                            Text("Write what you remember…")
                                .font(.outfit(14))
                                .foregroundColor(.white.opacity(0.2))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $transcript)
                            .font(.outfit(14))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 220)
                    }
                }
                .padding(20)
                .background(Color.driftCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let err = errorMessage {
                    Text(err)
                        .font(.outfit(13))
                        .foregroundColor(.driftCoral)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await reinterpret() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Re-interpret Dream")
                            .font(.outfit(15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.driftPurple, .driftPurpleDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Color.clear.frame(height: 40)
            }
            .padding(16)
        }
    }

    // MARK: - Preview view

    private func previewView(_ interp: DreamInterpretation) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.driftTeal)
                    Text("New interpretation ready")
                        .font(.cormorant(22, weight: .bold, italic: true))
                        .foregroundColor(.white)
                    Text("Review below, then tap Apply to save.")
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.driftCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HeroCard(
                    emojis: interp.emojis,
                    title: interp.title,
                    snippet: interp.snippet,
                    tags: interp.tags,
                    vividness: interp.vividness,
                    mode: mode
                )
                ReflectionCard(
                    inner: interp.reflection.inner,
                    esoteric: interp.reflection.esoteric,
                    mode: mode
                )
                if let pattern = interp.pattern, !pattern.isEmpty {
                    PatternCard(pattern: pattern)
                }
                ForEach(Array(interp.symbols.enumerated()), id: \.offset) { _, sym in
                    SymbolCard(symbol: sym, mode: mode)
                }
                JournalPromptCard(
                    inner: interp.journalPrompts.inner,
                    esoteric: interp.journalPrompts.esoteric,
                    mode: mode
                )
                EmotionalSignatureSection(emotions: interp.emotionalSignature)
                    .padding(20)
                    .background(Color.driftCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 12) {
                    Button {
                        withAnimation { pendingInterpretation = nil }
                    } label: {
                        Text("← Try again")
                            .font(.outfit(14, weight: .semibold))
                            .foregroundColor(.driftPurple)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.driftPurple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.driftPurple, lineWidth: 1)
                            }
                    }

                    Button {
                        applyInterpretation(interp)
                    } label: {
                        Text("Apply ✓")
                            .font(.outfit(14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.driftPurple)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Color.clear.frame(height: 40)
            }
            .padding(16)
        }
    }

    // MARK: - Actions

    private func saveOnly() {
        dream.transcript = transcript
        dream.interpretationMode = mode
        dismiss()
    }

    private func reinterpret() async {
        if !storeService.isSubscribed && interpretationCount >= 7 {
            showPaywall = true
            return
        }

        errorMessage = nil
        let previous = allDreams.filter { $0.id != dream.id }.prefix(3)
        withAnimation { isInterpreting = true }
        do {
            let result = try await ClaudeService.interpret(
                transcript: transcript,
                mode: mode,
                previousDreams: Array(previous),
                language: language
            )
            interpretationCount += 1
            withAnimation {
                isInterpreting = false
                pendingInterpretation = result
            }
        } catch {
            withAnimation { isInterpreting = false }
            errorMessage = "Re-interpretation failed: \(error.localizedDescription)"
        }
    }

    private func applyInterpretation(_ interp: DreamInterpretation) {
        dream.transcript = transcript
        dream.interpretationMode = mode
        dream.title = interp.title
        dream.emojis = interp.emojis
        dream.tags = interp.tags
        dream.vividness = interp.vividness
        dream.snippet = interp.snippet
        dream.reflectionInner = interp.reflection.inner
        dream.reflectionEsoteric = interp.reflection.esoteric
        dream.pattern = interp.pattern
        dream.journalPromptInner = interp.journalPrompts.inner
        dream.journalPromptEsoteric = interp.journalPrompts.esoteric
        dream.emotionalSignature = interp.emotionalSignature

        dream.symbols = interp.symbols.map {
            DreamSymbol(
                name: $0.name,
                emoji: $0.emoji,
                category: $0.category,
                inner: $0.inner,
                esoteric: $0.esoteric
            )
        }
        dismiss()
    }
}
