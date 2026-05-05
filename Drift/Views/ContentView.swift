import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .tonight
    @StateObject private var whisperService = WhisperKitService()

    enum Tab: Int, CaseIterable {
        case tonight, record, journal, patterns
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.driftBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                TonightView(selectedTab: $selectedTab)
                    .tag(Tab.tonight)

                RecordView(selectedTab: $selectedTab)
                    .environmentObject(whisperService)
                    .tag(Tab.record)

                JournalView()
                    .tag(Tab.journal)

                PatternsView()
                    .tag(Tab.patterns)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            DriftTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct DriftTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    struct TabItem {
        let tab: ContentView.Tab
        let icon: String
        let label: String
    }

    let items: [TabItem] = [
        .init(tab: .tonight,  icon: "moon.stars.fill",    label: "Tonight"),
        .init(tab: .record,   icon: "mic.fill",           label: "Record"),
        .init(tab: .journal,  icon: "book.fill",          label: "Journal"),
        .init(tab: .patterns, icon: "sparkles",            label: "Patterns"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = item.tab
                    }
                } label: {
                    let active = selectedTab == item.tab
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .medium))
                        Text(item.label)
                            .font(.outfit(10, weight: .medium))
                    }
                    .foregroundColor(active ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        active
                            ? RoundedRectangle(cornerRadius: 20).fill(Color.driftPurple)
                            : nil
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background {
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color.driftNavy.opacity(0.7)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
