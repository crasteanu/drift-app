import SwiftUI
import SwiftData
import Charts

struct YearInDreamsView: View {
    @Query(sort: \Dream.date, order: .reverse) private var allDreams: [Dream]
    @Environment(\.dismiss) private var dismiss

    private let calendar = Calendar.current
    private let currentYear = Calendar.current.component(.year, from: Date())

    private var dreams: [Dream] {
        allDreams.filter { calendar.component(.year, from: $0.date) == currentYear }
    }

    private var symbolCount: Int { PatternEngine.allSymbolLibrary(from: dreams).count }
    private var avgVividness: Int {
        guard !dreams.isEmpty else { return 0 }
        return dreams.map { $0.vividness }.reduce(0, +) / dreams.count
    }

    private var monthlyData: [(label: String, count: Int)] {
        let abbr = Calendar.current.shortStandaloneMonthSymbols
        return (1...12).map { month in
            let count = dreams.filter { calendar.component(.month, from: $0.date) == month }.count
            return (abbr[month - 1], count)
        }
    }

    private var topSymbols: [(name: String, emoji: String, category: String, count: Int)] {
        PatternEngine.allSymbolLibrary(from: dreams)
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    private var mostVivid: Dream? { dreams.max(by: { $0.vividness < $1.vividness }) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        heroCard
                        statsRow
                        monthlyHeatmap
                        symbolPodium
                        if let d = mostVivid {
                            mostVividCard(d)
                        }
                        bottomButtons
                        Color.clear.frame(height: 40)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Year in Dreams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.driftPurple)
                        .font(.outfit(15, weight: .semibold))
                }
            }
        }
    }

    @ViewBuilder
    private var heroCard: some View {
        VStack(spacing: 8) {
            // Year with last digit teal
            let yearStr = String(currentYear)
            HStack(spacing: 0) {
                Text(yearStr.dropLast())
                    .font(.cormorant(72, weight: .bold))
                    .foregroundColor(.white)
                Text(yearStr.last.map(String.init) ?? "")
                    .font(.cormorant(72, weight: .bold))
                    .foregroundColor(.driftTeal)
            }

            Text("Your dream year in review")
                .font(.cormorant(20, italic: true))
                .foregroundColor(.white.opacity(0.7))

            Text("Generated from \(dreams.count) dream entries · \(formattedMonth()) \(currentYear)")
                .font(.outfit(12))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(dreams.count)", label: "Dreams")
            statTile(value: "\(symbolCount)", label: "Symbols")
            statTile(value: "\(avgVividness)", label: "Avg Vivid")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.cormorant(30, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.outfit(12))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var monthlyHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Heatmap")
                .font(.outfit(14, weight: .semibold))
                .foregroundColor(.white)

            Chart(monthlyData, id: \.label) { item in
                BarMark(x: .value("Month", item.label), y: .value("Dreams", item.count))
                    .foregroundStyle(Color.driftPurple)
                    .cornerRadius(4)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.white.opacity(0.5)) }
            }
            .chartYAxis {
                AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.white.opacity(0.3)) }
            }
        }
        .padding(16)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var symbolPodium: some View {
        if topSymbols.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Symbol Podium")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.white)

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(Array(topSymbols.enumerated()), id: \.offset) { _, sym in
                        symbolPodiumBar(sym)
                    }
                }
            }
            .padding(16)
            .background(Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func symbolPodiumBar(_ sym: (name: String, emoji: String, category: String, count: Int)) -> some View {
        VStack(spacing: 4) {
            Text(sym.emoji).font(.system(size: 22))
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient.driftTealPurple)
                .frame(width: 32, height: max(8, CGFloat(sym.count) * 18))
            Text(sym.category)
                .font(.outfit(9))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func mostVividCard(_ dream: Dream) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Vivid Dream")
                .font(.outfit(13))
                .foregroundColor(.white.opacity(0.4))

            Text("\(dream.vividness)")
                .font(.cormorant(52, weight: .bold, italic: true))
                .foregroundColor(.driftCoral)

            Text(dream.title)
                .font(.cormorant(22, weight: .bold, italic: true))
                .foregroundColor(.white)

            Text(dream.formattedDate)
                .font(.outfit(12))
                .foregroundColor(.white.opacity(0.4))

            Text(dream.snippet)
                .font(.outfit(13))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var bottomButtons: some View {
        Button { shareYear() } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Your Year in Dreams")
            }
            .font(.outfit(14, weight: .semibold))
            .foregroundColor(.driftPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.driftPurple.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.driftPurple, lineWidth: 1))
        }
    }

    private func shareYear() {
        let topSym = topSymbols.prefix(3).map { "\($0.emoji) \($0.name)" }.joined(separator: ", ")
        let vivid = mostVivid.map { "\"\($0.title)\" (\($0.vividness)/100)" } ?? "—"
        let text = """
        ✦ My \(currentYear) in Dreams — drift.

        \(dreams.count) dreams recorded
        \(symbolCount) symbols discovered
        Avg vividness: \(avgVividness)/100

        Top symbols: \(topSym.isEmpty ? "none yet" : topSym)
        Most vivid: \(vivid)

        Captured with drift. — dream journal
        """
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var presenter = root
        while let next = presenter.presentedViewController { presenter = next }
        presenter.present(av, animated: true)
    }

    private func formattedMonth() -> String {
        calendar.standaloneMonthSymbols[calendar.component(.month, from: Date()) - 1]
    }
}

