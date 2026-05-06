import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var searchText = ""
    @State private var activeFilter: Filter = .all
    @State private var selectedDream: Dream?
    @State private var cachedTotalSymbols: Int = 0
    @State private var cachedGrouped: [(String, [Dream])] = []

    enum Filter: String, CaseIterable {
        case all = "All"
        case starred = "Starred"
        case recurring = "Recurring"
        case vivid = "Vivid"
        case anxious = "Anxious"
    }

    private var filtered: [Dream] {
        var result = dreams

        switch activeFilter {
        case .all: break
        case .starred: result = result.filter { $0.isStarred }
        case .vivid:   result = result.filter { $0.vividness >= 70 }
        case .anxious:
            let anxiousWords: Set<String> = ["anxiety", "anxious", "fear", "afraid", "stress", "stressed"]
            result = result.filter {
                $0.emotionalSignature.contains { anxiousWords.contains($0.lowercased()) }
            }
        case .recurring:
            let allTags = dreams.flatMap { $0.tags }
            let tagFreq = Dictionary(grouping: allTags, by: { $0.lowercased() }).filter { $0.value.count > 1 }.keys
            result = result.filter { d in d.tags.contains { tagFreq.contains($0.lowercased()) } }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(q)
                || $0.transcript.localizedCaseInsensitiveContains(q)
                || $0.tags.contains { $0.localizedCaseInsensitiveContains(q) }
            }
        }
        return result
    }

    private static let groupFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private func rebuildCache() {
        cachedTotalSymbols = Set(dreams.flatMap { $0.symbols.map { $0.name.lowercased() } }).count
        let dict = Dictionary(grouping: filtered) { JournalView.groupFormatter.string(from: $0.date) }
        cachedGrouped = dict
            .map { key, groupDreams -> (String, [Dream], Date) in
                let sorted = groupDreams.sorted { $0.date > $1.date }
                return (key, sorted, sorted.first?.date ?? .distantPast)
            }
            .sorted { $0.2 > $1.2 }
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                        TextField("Search dreams…", text: $searchText)
                            .font(.outfit(14))
                            .foregroundColor(.white)
                            .tint(.driftTeal)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.driftCard)
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Filter.allCases, id: \.self) { filter in
                                FilterChip(filter: filter, active: activeFilter == filter) {
                                    withAnimation(.spring(response: 0.3)) { activeFilter = filter }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }

                    // Dream list
                    if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("🌑")
                                .font(.system(size: 48))
                            Text(searchText.isEmpty ? "No dreams yet.\nRecord your first dream tonight." : "No dreams match your search.")
                                .font(.cormorant(20, italic: true))
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                                ForEach(cachedGrouped, id: \.0) { month, monthDreams in
                                    Section {
                                        ForEach(monthDreams) { dream in
                                            Button {
                                                selectedDream = dream
                                            } label: {
                                                DreamRowCard(dream: dream)
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.horizontal, 16)
                                        }
                                    } header: {
                                        HStack {
                                            Text(month)
                                                .font(.outfit(14, weight: .semibold))
                                                .foregroundStyle(LinearGradient.driftTealPurple)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.driftBackground)
                                    }
                                }
                                Color.clear.frame(height: 90)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dream Journal")
                        .font(.cormorant(28, weight: .bold, italic: true))
                        .foregroundStyle(LinearGradient.driftTealPurple)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(dreams.count) dreams · \(cachedTotalSymbols) symbols")
                        .font(.outfit(12, weight: .medium))
                        .foregroundColor(.driftTagGreen)
                }
            }
            .sheet(item: $selectedDream) { dream in
                ReflectionView(dream: dream, isReadOnly: true)
            }
            .onAppear { rebuildCache() }
            .onChange(of: dreams) { rebuildCache() }
            .onChange(of: searchText) { rebuildCache() }
            .onChange(of: activeFilter) { rebuildCache() }
        }
    }
}

struct FilterChip: View {
    let filter: JournalView.Filter
    let active: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(filter.rawValue)
                .font(.outfit(13, weight: active ? .semibold : .regular))
                .foregroundColor(active ? .white : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? Color.driftPurple : Color.driftCard)
                .clipShape(Capsule())
                .overlay(active ? nil : Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
