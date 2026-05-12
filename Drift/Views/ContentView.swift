import SwiftUI

struct ContentView: View {
    @Environment(StoreService.self) private var storeService
    @State private var selectedTab: Tab = .tonight
    @StateObject private var whisperService = WhisperKitService()
    @State private var showPaywall = false

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

            DriftTabBar(
                selectedTab: $selectedTab,
                isSubscribed: storeService.isSubscribed,
                onLockedPatternsTap: { showPaywall = true }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        .task { await whisperService.prepare() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .patternsLock)
        }
    }
}

struct DriftTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    var isSubscribed: Bool = true
    var onLockedPatternsTap: () -> Void = {}

    struct TabItem {
        let tab: ContentView.Tab
        let icon: String
        let label: String
    }

    let items: [TabItem] = [
        .init(tab: .tonight,  icon: "moon.stars.fill", label: "Tonight"),
        .init(tab: .record,   icon: "mic.fill",        label: "Record"),
        .init(tab: .journal,  icon: "book.fill",       label: "Journal"),
        .init(tab: .patterns, icon: "sparkles",         label: "Patterns"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.label) { item in
                let isPatternLocked = item.tab == .patterns && !isSubscribed
                Button {
                    if isPatternLocked {
                        onLockedPatternsTap()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = item.tab
                        }
                    }
                } label: {
                    let active = selectedTab == item.tab
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .medium))
                            if isPatternLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.driftAmber)
                                    .background(
                                        Circle()
                                            .fill(Color.driftBackground)
                                            .padding(-2)
                                    )
                                    .offset(x: 7, y: -5)
                            }
                        }
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
