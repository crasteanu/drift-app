import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    /// Versioned container with migration plan so future schema changes
    /// don't corrupt existing user data. Built once at app start.
    private let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Dream.self, DreamSymbol.self,
                migrationPlan: DriftMigrationPlan.self
            )
        } catch {
            // Store is unreadable — wipe and start fresh rather than crash-looping.
            // This is a last-resort safety net; normal upgrades go through migration stages.
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            // swiftlint:disable:next force_try
            return try! ModelContainer(
                for: Dream.self, DreamSymbol.self,
                migrationPlan: DriftMigrationPlan.self
            )
        }
    }()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        // White tint so toolbar buttons/titles render light without needing per-view toolbarColorScheme
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenWelcome {
                    ContentView()
                } else {
                    WelcomeView()
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
