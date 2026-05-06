import Foundation
import WhisperKit

@MainActor
final class WhisperKitService: ObservableObject {
    @Published var state: ServiceState = .idle
    @Published var downloadProgress: Double = 0

    enum ServiceState {
        case idle
        case downloading
        case ready
        case transcribing
        case error(String)
    }

    private var whisperKit: WhisperKit?

    func prepare() async {
        guard whisperKit == nil else { return }
        state = .downloading

        do {
            let config = WhisperKitConfig(model: "small", verbose: false, prewarm: true, load: true)
            let wk = try await WhisperKit(config)
            whisperKit = wk
            state = .ready
            downloadProgress = 1.0
        } catch {
            state = .error("Model download failed: \(error.localizedDescription)")
        }
    }

    func transcribe(url: URL, language: String = "ro") async throws -> String {
        guard let wk = whisperKit else {
            await prepare()
            guard let wk2 = whisperKit else {
                throw TranscriptionError.notReady
            }
            return try await doTranscribe(wk: wk2, url: url, language: language)
        }
        return try await doTranscribe(wk: wk, url: url, language: language)
    }

    private func doTranscribe(wk: WhisperKit, url: URL, language: String) async throws -> String {
        state = .transcribing
        defer { if case .transcribing = state { state = .ready } }

        var options = DecodingOptions()
        options.language = language == "auto" ? nil : language
        options.task = .transcribe
        options.chunkingStrategy = .vad
        options.initialPrompt = "Jurnal de vise. Vis, somn, noapte, adormit, trezit, coșmar, personaj, loc, senzație, emoție, frică, bucurie, zbor, fugă, apă, casă, pădure, oraș."

        let resolvedPath = url.resolvingSymlinksInPath().path(percentEncoded: false)
        let results = try await wk.transcribe(audioPath: resolvedPath, decodeOptions: options)
        return results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }

    var isDownloading: Bool {
        if case .downloading = state { return true }
        return false
    }
}

enum TranscriptionError: LocalizedError {
    case notReady
    var errorDescription: String? { "Transcription model not ready" }
}
