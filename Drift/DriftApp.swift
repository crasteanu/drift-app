import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

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
        .modelContainer(for: [Dream.self, DreamSymbol.self])
    }
}
