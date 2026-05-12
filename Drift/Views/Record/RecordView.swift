import SwiftUI
import SwiftData

struct RecordView: View {
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject private var whisperService: WhisperKitService
    @StateObject private var recorder = RecordingService()
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @Environment(\.modelContext) private var context

    @State private var mode: String = InterpretationMode.both.rawValue
    @State private var showTextInput = false
    @FocusState private var isTextEditorFocused: Bool
    @State private var manualText = ""
    @State private var transcript = ""
    @State private var processingState: ProcessingState = .idle
    @State private var recordingDuration: TimeInterval = 0
    @State private var orbShimmer = false
    @State private var arcRotation: Double = 0
    @State private var interpretation: DreamInterpretation?
    @State private var savedDream: Dream?
    @State private var error: String?
    @AppStorage("whisperLanguage") private var language = "ro"
    @Environment(StoreService.self) private var storeService
    @AppStorage("interpretationCount") private var interpretationCount: Int = 0
    @State private var showPaywall = false

    enum ProcessingState {
        case idle, recording, transcribing, transcribed, interpreting, done, error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground
                    .ignoresSafeArea()
                    .onTapGesture { isTextEditorFocused = false }

                if case .interpreting = processingState {
                    LoadingView()
                        .transition(.opacity)
                } else if let interp = interpretation, case .done = processingState {
                    ReflectionView(
                        interpretation: interp,
                        transcript: transcript,
                        mode: mode,
                        recordingDuration: recordingDuration,
                        dreams: Array(dreams),
                        onRetry: resetState,
                        onFinish: resetState,
                        preloadedDream: savedDream
                    )
                    .transition(.opacity)
                } else if case .transcribed = processingState {
                    transcribedView
                        .transition(.opacity)
                } else if case .error = processingState, !transcript.isEmpty {
                    transcribedView
                        .transition(.opacity)
                } else {
                    recordingBody
                }
            }
            .animation(.easeInOut(duration: 0.4), value: processingState)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Record a Dream")
                        .font(.cormorant(28, weight: .bold, italic: true))
                        .foregroundStyle(LinearGradient.driftTealPurple)
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .record {
                switch processingState {
                case .done, .transcribed, .error: resetState()
                default: break
                }
            }
        }
        .onReceive(recorder.$error) { recorderError in
            guard let recorderError else { return }
            error = recorderError.localizedDescription
            if case .recording = processingState { processingState = .idle }
        }
        .onDisappear {
            if case .done = processingState { resetState() }
        }
        .task { await recorder.warmUp() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .interpretationLimit)
        }
    }

    @ViewBuilder
    private var recordingBody: some View {
        VStack(spacing: 0) {
            Spacer()

            if showTextInput {
                textInputMode
            } else {
                voiceMode
            }

            Spacer()

            // Mode selector
            VStack(spacing: 8) {
                ModePickerView(selected: $mode)

                Text("Interpretation style")
                    .font(.outfit(11))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.bottom, 110)

            if let err = error {
                Text(err)
                    .font(.outfit(13))
                    .foregroundColor(.driftCoral)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var voiceMode: some View {
        VStack(spacing: 32) {
            if !recorder.isRecording, case .idle = processingState {
                VStack(spacing: 10) {
                    Text("The night holds its secrets")
                        .font(.cormorant(30, weight: .bold, italic: true))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Tap the orb to begin")
                        .font(.outfit(14))
                        .foregroundColor(.driftTagGreen)
                }
                .padding(.horizontal, 32)
            }

            // Transcribing state
            if case .transcribing = processingState {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(.driftTeal)
                    Text(whisperService.isDownloading ? "Preparing model…" : "Transcribing…")
                        .font(.outfit(13))
                        .foregroundColor(.driftTeal)
                }
                .transition(.opacity)
            }

            OrbVisualizer(
                audioLevel: recorder.audioLevel,
                isRecording: recorder.isRecording,
                onTap: handleOrbTap
            )
            .frame(width: 240, height: 240)
            .opacity(whisperService.isDownloading && !recorder.isRecording ? (orbShimmer ? 0.55 : 0.75) : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    orbShimmer = true
                }
            }
            .overlay {
                if whisperService.isDownloading {
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(Color.driftTeal, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(arcRotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                arcRotation = 360
                            }
                        }
                        .transition(.opacity)
                }
            }

            if recorder.isRecording {
                VStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.driftCoral)
                            .frame(width: 8, height: 8)
                        Text(formatDuration(recorder.duration))
                            .font(.outfit(16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    if !transcript.isEmpty {
                        Text(transcript)
                            .font(.outfit(14))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .lineLimit(4)
                    } else {
                        Text("Listening…")
                            .font(.outfit(13))
                            .foregroundColor(.white.opacity(0.35))
                    }

                    Button(action: stopAndTranscribe) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                            Text("Stop Recording")
                                .font(.outfit(15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Color.driftCoral)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }

            if !recorder.isRecording, processingState == .idle {
                Button {
                    withAnimation { showTextInput = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 13))
                        Text("Type instead")
                            .font(.outfit(14, weight: .semibold))
                    }
                    .foregroundColor(.driftYellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.driftCard)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var textInputMode: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Describe your dream")
                    .font(.cormorant(28, weight: .bold, italic: true))
                    .foregroundColor(.white)
                Text("Write whatever you remember")
                    .font(.outfit(13))
                    .foregroundColor(.white.opacity(0.4))
            }

            ZStack(alignment: .topLeading) {
                if manualText.isEmpty {
                    Text("I dreamed of…")
                        .font(.outfit(15))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $manualText)
                    .font(.outfit(15))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .focused($isTextEditorFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { isTextEditorFocused = false }
                                .font(.outfit(14, weight: .semibold))
                                .foregroundColor(.driftPurple)
                        }
                    }
            }
            .background(Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button {
                    isTextEditorFocused = false
                    withAnimation { showTextInput = false }
                } label: {
                    Text("Cancel")
                        .font(.outfit(14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.driftPurple, .driftPurpleDark], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    guard !manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    transcript = manualText
                    withAnimation { processingState = .transcribed }
                } label: {
                    HStack(spacing: 6) {
                        Text("Continue")
                            .font(.outfit(14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.driftPurple, .driftPurpleDark], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var transcribedView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Dream captured")
                        .font(.cormorant(30, weight: .bold, italic: true))
                        .foregroundColor(.white)
                    Text("Choose a style, then interpret")
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 8)

                // Transcript preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transcript")
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.35))
                    Text(transcript)
                        .font(.outfit(15))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.driftCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Mode selector
                VStack(spacing: 8) {
                    Text("Interpretation style")
                        .font(.outfit(12))
                        .foregroundColor(.white.opacity(0.35))

                    ModePickerView(selected: $mode)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.driftCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                if let err = error {
                    Text(err)
                        .font(.outfit(13))
                        .foregroundColor(.driftCoral)
                        .multilineTextAlignment(.center)
                }

                if !storeService.isSubscribed && interpretationCount < 7 {
                    Text("\(7 - interpretationCount) free interpretation\(7 - interpretationCount == 1 ? "" : "s") left")
                        .font(.outfit(12))
                        .foregroundColor(.driftAmber)
                }

                Button {
                    Task { await interpretDream() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Interpret Dream")
                            .font(.outfit(16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [.driftPurple, .driftPurpleDark], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    withAnimation { processingState = .idle; transcript = ""; manualText = ""; showTextInput = false }
                } label: {
                    Text("← Record again")
                        .font(.outfit(14, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    private func handleOrbTap() {
        if recorder.isRecording {
            stopAndTranscribe()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        error = nil
        Task {
            if !recorder.isWarm {
                guard await recorder.requestPermission() else {
                    error = "Microphone access required. Enable it in Settings."
                    return
                }
            }
            do {
                try await recorder.start()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation { processingState = .recording }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func stopAndTranscribe() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let peak = recorder.peakAudioLevel
        recordingDuration = recorder.stop()
        guard peak > 0.08 else {
            self.error = "Nothing was picked up. Please try again."
            processingState = .idle
            return
        }
        guard let url = recorder.recordingURL else {
            self.error = "Recording file not found"
            return
        }
        withAnimation { processingState = .transcribing }

        Task {
            do {
                let text = try await whisperService.transcribe(url: url, language: language)
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.error = "Nothing was recorded. Please try again."
                    processingState = .idle
                    return
                }
                transcript = text
                withAnimation { processingState = .transcribed }
            } catch {
                self.error = "Transcription failed: \(error.localizedDescription)"
                processingState = .idle
            }
        }
    }

    private func resetState() {
        withAnimation(.easeInOut(duration: 0.3)) {
            processingState = .idle
            interpretation = nil
            savedDream = nil
            transcript = ""
            manualText = ""
            recordingDuration = 0
            error = nil
        }
    }

    private func interpretDream() async {
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "No transcript to interpret."
            processingState = .idle
            return
        }

        if !storeService.isSubscribed && interpretationCount >= 7 {
            showPaywall = true
            return
        }

        withAnimation { processingState = .interpreting }
        do {
            let result = try await ClaudeService.interpret(
                transcript: transcript,
                mode: mode,
                previousDreams: Array(dreams.prefix(3)),
                language: language
            )
            interpretation = result
            saveDream(from: result)
            interpretationCount += 1
            withAnimation { processingState = .done }
        } catch {
            let msg = error.localizedDescription
            self.error = "Interpretation failed: \(msg)"
            withAnimation { processingState = .error(msg) }
        }
    }

    private func saveDream(from interp: DreamInterpretation) {
        let symbols = interp.symbols.map { s in
            DreamSymbol(name: s.name, emoji: s.emoji, category: s.category, inner: s.inner, esoteric: s.esoteric)
        }
        let d = Dream(
            transcript: transcript,
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
            interpretationMode: mode,
            recordingDuration: recordingDuration
        )
        context.insert(d)
        savedDream = d
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "\(s)s"
    }
}

extension RecordView.ProcessingState: Equatable {
    static func == (lhs: RecordView.ProcessingState, rhs: RecordView.ProcessingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording), (.transcribing, .transcribing),
             (.transcribed, .transcribed), (.interpreting, .interpreting), (.done, .done): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}
