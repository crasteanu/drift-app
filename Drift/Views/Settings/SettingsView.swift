import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var dreams: [Dream]

    @AppStorage("whisperLanguage") private var language = "ro"
    @AppStorage("morningReminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var showLanguagePicker = false
    @State private var showDeleteConfirm = false
    @State private var showPrivacy = false
    @State private var reminderTime = Date()
    @State private var storageSizeText: String = "…"
    @State private var symbolCountText: String = "…"

    private let languages: [(code: String, flag: String, name: String)] = [
        ("ro", "🇷🇴", "Romanian"),
        ("en", "🇺🇸", "English"),
        ("fr", "🇫🇷", "French"),
        ("de", "🇩🇪", "German"),
        ("es", "🇪🇸", "Spanish"),
        ("it", "🇮🇹", "Italian"),
        ("pt", "🇵🇹", "Portuguese"),
        ("nl", "🇳🇱", "Dutch"),
        ("pl", "🇵🇱", "Polish"),
        ("ru", "🇷🇺", "Russian"),
        ("uk", "🇺🇦", "Ukrainian"),
        ("cs", "🇨🇿", "Czech"),
        ("sk", "🇸🇰", "Slovak"),
        ("hu", "🇭🇺", "Hungarian"),
        ("hr", "🇭🇷", "Croatian"),
        ("sv", "🇸🇪", "Swedish"),
        ("no", "🇳🇴", "Norwegian"),
        ("da", "🇩🇰", "Danish"),
        ("fi", "🇫🇮", "Finnish"),
        ("tr", "🇹🇷", "Turkish"),
        ("ar", "🇸🇦", "Arabic"),
        ("he", "🇮🇱", "Hebrew"),
        ("ja", "🇯🇵", "Japanese"),
        ("zh", "🇨🇳", "Chinese"),
        ("ko", "🇰🇷", "Korean"),
        ("hi", "🇮🇳", "Hindi"),
        ("id", "🇮🇩", "Indonesian"),
        ("auto", "🌐", "Auto-detect"),
    ]

    private var currentLang: (code: String, flag: String, name: String) {
        languages.first { $0.code == language } ?? languages[0]
    }

    private func computeStorageSize() async -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let storeURL = appSupport?.appendingPathComponent("default.store")
        if let storeURL, let bytes = directorySize(at: storeURL), bytes > 0 {
            return formatBytes(bytes)
        }
        let estimated = dreams.reduce(0) { total, dream in
            let dreamBytes = [
                dream.transcript, dream.title, dream.snippet,
                dream.reflectionInner, dream.reflectionEsoteric,
                dream.pattern ?? "", dream.journalPromptInner,
                dream.journalPromptEsoteric, dream.interpretationMode
            ].reduce(0) { $0 + $1.utf8.count }
            + dream.tags.joined().utf8.count
            + dream.emojis.joined().utf8.count
            + dream.emotionalSignature.joined().utf8.count
            + dream.symbols.reduce(0) { s, sym in
                s + sym.name.utf8.count + sym.emoji.utf8.count
                  + sym.category.utf8.count + sym.inner.utf8.count + sym.esoteric.utf8.count
            }
            + 256
            return total + dreamBytes
        }
        return formatBytes(estimated)
    }

    private func directorySize(at url: URL) -> Int? {
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }
        var total = 0
        for case let fileURL as URL in enumerator {
            total += (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
        return total > 0 ? total : nil
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()
                List {
                    // Voice language
                    Section {
                        Button {
                            showLanguagePicker = true
                        } label: {
                            HStack {
                                Text(currentLang.flag)
                                    .font(.system(size: 22))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice Recognition Language")
                                        .font(.outfit(14, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(currentLang.name)
                                        .font(.outfit(12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .listRowBackground(Color.driftCard)
                    }

                    // Morning reminder
                    Section {
                        Toggle(isOn: $reminderEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Morning Reminder")
                                    .font(.outfit(14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Daily notification at your chosen time")
                                    .font(.outfit(12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .tint(.driftPurple)
                        .listRowBackground(Color.driftCard)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled { scheduleReminder() } else { cancelReminder() }
                        }

                        if reminderEnabled {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .colorScheme(.dark)
                                .font(.outfit(14))
                                .foregroundColor(.white)
                                .listRowBackground(Color.driftCard)
                                .onChange(of: reminderTime) { _, _ in scheduleReminder() }
                        }
                    }

                    // Data
                    Section {
                        dataRow(label: "Dreams recorded", value: "\(dreams.count)")
                        dataRow(label: "Symbols detected", value: symbolCountText)
                        dataRow(label: "Storage", value: storageSizeText)
                    } header: {
                        Text("Your Data")
                            .font(.outfit(13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Export
                    Section {
                        exportButton(icon: "doc.text", label: "Export as plain text") { exportText() }
                        exportButton(icon: "curlybraces", label: "Export as JSON") { exportJSON() }
                    } header: {
                        Text("Export")
                            .font(.outfit(13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Danger zone
                    Section {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete all dream data", systemImage: "trash")
                                .font(.outfit(14, weight: .medium))
                                .foregroundColor(.driftCoral)
                        }
                        .listRowBackground(Color.driftCard)
                    } header: {
                        Text("Danger Zone")
                            .font(.outfit(13, weight: .semibold))
                            .foregroundColor(.driftCoral.opacity(0.7))
                    }

                    // About
                    Section {
                        Button { showPrivacy = true } label: {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .font(.outfit(14))
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.driftCard)

                        HStack {
                            Text("Version")
                                .font(.outfit(14))
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0")
                                .font(.outfit(14))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .listRowBackground(Color.driftCard)
                    } header: {
                        Text("About")
                            .font(.outfit(13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.driftBackground)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.outfit(15, weight: .semibold))
                        .foregroundColor(.driftPurple)
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                languagePickerSheet
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyView()
            }
            .alert("Delete all dream data?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone. All dreams, symbols, and patterns will be permanently removed.")
            }
        }
        .onAppear {
            var comps = DateComponents()
            comps.hour = reminderHour
            comps.minute = reminderMinute
            reminderTime = Calendar.current.date(from: comps) ?? Date()
        }
        .task(id: dreams.count) {
            storageSizeText = await computeStorageSize()
            symbolCountText = "\(PatternEngine.allSymbolLibrary(from: dreams).count)"
        }
    }

    private var languagePickerSheet: some View {
        // No NavigationStack here — SettingsView already owns one; presenting a second
        // NavigationStack from a sheet inside it causes the "nested navigation bar" crash.
        ZStack {
            Color.driftBackground.ignoresSafeArea()
            List(languages, id: \.code) { lang in
                Button {
                    language = lang.code
                    showLanguagePicker = false
                } label: {
                    HStack {
                        Text(lang.flag).font(.system(size: 22))
                        Text(lang.name).font(.outfit(14)).foregroundColor(.white)
                        Spacer()
                        if lang.code == language {
                            Image(systemName: "checkmark").foregroundColor(.driftPurple)
                        }
                    }
                }
                .listRowBackground(Color.driftCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.driftBackground)
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { showLanguagePicker = false }.foregroundColor(.driftPurple)
            }
        }
    }

    private func dataRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.outfit(14)).foregroundColor(.white)
            Spacer()
            Text(value).font(.outfit(14)).foregroundColor(.white.opacity(0.5))
        }
        .listRowBackground(Color.driftCard)
    }

    private func exportButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.outfit(14))
                .foregroundColor(.white)
        }
        .listRowBackground(Color.driftCard)
    }

    private func scheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "drift."
            content.body = "What did you dream about last night? Capture it before it fades."
            content.sound = .default

            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request = UNNotificationRequest(identifier: "drift.morning", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)

            DispatchQueue.main.async {
                reminderHour = comps.hour ?? 8
                reminderMinute = comps.minute ?? 0
            }
        }
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["drift.morning"])
    }

    private func deleteAll() {
        for dream in dreams { context.delete(dream) }
    }

    private func exportText() {
        let lines = dreams.map { d -> String in
            var parts: [String] = [
                "\(d.formattedDate) — \(d.title)",
                "Vividness: \(d.vividness)/100",
            ]
            if !d.tags.isEmpty { parts.append("Tags: \(d.tags.joined(separator: ", "))") }
            parts.append("\nTranscript:\n\(d.transcript)")
            if !d.reflectionInner.isEmpty  { parts.append("\nInner Reflection:\n\(d.reflectionInner)") }
            if !d.reflectionEsoteric.isEmpty { parts.append("\nEsoteric Reflection:\n\(d.reflectionEsoteric)") }
            if !d.symbols.isEmpty {
                let symLines = d.symbols.map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
                parts.append("Symbols: \(symLines)")
            }
            if !d.emotionalSignature.isEmpty { parts.append("Emotional signature: \(d.emotionalSignature.joined(separator: ", "))") }
            parts.append("---")
            return parts.joined(separator: "\n")
        }
        share(lines.joined(separator: "\n\n"), filename: "drift_dreams.txt")
    }

    private func exportJSON() {
        let data = dreams.map { d -> [String: Any] in
            var dict: [String: Any] = [
                "id": d.id.uuidString,
                "date": d.formattedDate,
                "title": d.title,
                "emojis": d.emojis,
                "tags": d.tags,
                "vividness": d.vividness,
                "transcript": d.transcript,
                "snippet": d.snippet,
                "reflectionInner": d.reflectionInner,
                "reflectionEsoteric": d.reflectionEsoteric,
                "journalPromptInner": d.journalPromptInner,
                "journalPromptEsoteric": d.journalPromptEsoteric,
                "emotionalSignature": d.emotionalSignature,
                "interpretationMode": d.interpretationMode,
                "recordingDuration": d.recordingDuration,
                "isStarred": d.isStarred,
                "symbols": d.symbols.map { sym -> [String: Any] in [
                    "name": sym.name,
                    "emoji": sym.emoji,
                    "category": sym.category,
                    "inner": sym.inner,
                    "esoteric": sym.esoteric
                ]}
            ]
            if let pattern = d.pattern { dict["pattern"] = pattern }
            if let rating = d.sleepRating { dict["sleepRating"] = rating }
            return dict
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
              let json = String(data: jsonData, encoding: .utf8) else { return }
        share(json, filename: "drift_dreams.json")
    }

    private func share(_ text: String, filename: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard (try? text.write(to: url, atomically: true, encoding: .utf8)) != nil else { return }
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        // Walk up the presentation chain to find the topmost presented VC (e.g. the Settings sheet)
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        presenter.present(av, animated: true)
    }
}
