import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var storeService = StoreService()

    private let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Dream.self, DreamSymbol.self,
                migrationPlan: DriftMigrationPlan.self
            )
        } catch {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let url = config.url
            try? FileManager.default.removeItem(at: url)
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
            .environment(storeService)
            .task { await storeService.load() }
            .task { await storeService.listenForTransactions() }
        }
        .modelContainer(container)
    }
}
