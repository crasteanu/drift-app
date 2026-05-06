import AVFoundation
import Combine

@MainActor
final class RecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0 // 0–1 normalized
    @Published var duration: TimeInterval = 0
    @Published var error: Error?

    private var recorder: AVAudioRecorder?
    private var levelTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?
    private var startTime: Date?

    deinit {
        levelTask?.cancel()
        durationTask?.cancel()
    }

    var recordingURL: URL? {
        recorder?.url
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    func start() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record()

        isRecording = true
        startTime = Date()
        duration = 0

        levelTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.updateLevel()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        durationTask = Task { [weak self] in
            while !Task.isCancelled {
                if let self, let start = self.startTime {
                    self.duration = Date().timeIntervalSince(start)
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    func stop() -> TimeInterval {
        recorder?.stop()
        cancelPolling()
        isRecording = false
        audioLevel = 0
        let dur = duration
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return dur
    }

    private func cancelPolling() {
        levelTask?.cancel()
        durationTask?.cancel()
        levelTask = nil
        durationTask = nil
    }

    private func updateLevel() {
        guard let rec = recorder, rec.isRecording else { return }
        rec.updateMeters()
        let db = rec.averagePower(forChannel: 0)
        // Map -60dB..0dB to 0..1
        let normalized = max(0, min(1, (db + 60) / 60))
        audioLevel = normalized
    }
}

extension RecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard !flag else { return }
        Task { @MainActor in
            cancelPolling()
            isRecording = false
            audioLevel = 0
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.error = error
            cancelPolling()
            isRecording = false
            audioLevel = 0
        }
    }
}
