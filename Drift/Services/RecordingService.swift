import AVFoundation
import Combine

@MainActor
final class RecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0 // 0–1 normalized
    @Published var duration: TimeInterval = 0
    @Published var error: Error?

    static let maxDuration: TimeInterval = 15 * 60 // 15 minutes

    private var recorder: AVAudioRecorder?
    private var levelTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?
    private var maxDurationTask: Task<Void, Never>?
    private var startTime: Date?

    deinit {
        NotificationCenter.default.removeObserver(self)
        levelTask?.cancel()
        durationTask?.cancel()
        maxDurationTask?.cancel()
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

        // Listen for phone calls, alarms, and other interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )

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

        // Auto-stop after 15 minutes to prevent runaway recordings
        maxDurationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(RecordingService.maxDuration))
            guard !Task.isCancelled else { return }
            await self?.stopDueToMaxDuration()
        }
    }

    @MainActor
    private func stopDueToMaxDuration() {
        guard isRecording else { return }
        _ = stop()
        error = NSError(
            domain: "DriftRecording",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Recording stopped automatically after 15 minutes."]
        )
    }

    func stop() -> TimeInterval {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
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
        maxDurationTask?.cancel()
        levelTask = nil
        durationTask = nil
        maxDurationTask = nil
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

    // Called on an arbitrary thread by AVAudioSession
    @objc nonisolated func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            type == .began
        else { return }

        Task { @MainActor [weak self] in
            guard let self, self.isRecording else { return }
            _ = self.stop()
            self.error = NSError(
                domain: "DriftRecording",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Recording stopped: interrupted by a call or system alert."]
            )
        }
    }
}
