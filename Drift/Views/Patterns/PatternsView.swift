import SwiftUI
import SwiftData
import Charts

struct PatternsView: View {
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var showMoreInfo = false

    private let requiredDreams = 5

    private var insights: [PatternInsight] { PatternEngine.insights(from: dreams) }
    private var emotionalArc: [EmotionalDataPoint] { PatternEngine.emotionalArc(from: dreams) }
    private var topSymbols: [(symbol: String, emoji: String, count: Int)] { PatternEngine.topSymbols(from: dreams) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Info card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text("Patterns emerge from your words alone — no questionnaires.")
                                    .font(.outfit(13, weight: .semibold))
                                    .foregroundColor(showMoreInfo ? .driftTeal : .white.opacity(0.7))
                                Spacer()
                                Button(showMoreInfo ? "Less" : "More") {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        showMoreInfo.toggle()
                                    }
                                }
                                .font(.outfit(13, weight: .semibold))
                                .foregroundColor(.driftTeal)
                            }

                            if showMoreInfo {
                                Text("Drift reads the emotional tone, imagery, and language of every dream you record. The charts and clusters below reflect what your unconscious keeps returning to — inferred entirely from your own words.")
                                    .font(.outfit(13))
                                    .foregroundColor(.driftTeal)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(16)
                        .background(Color.driftCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        if dreams.count < requiredDreams {
                            lockedView
                        } else {
                            unlockedContent
                        }

                        Color.clear.frame(height: 90)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Pattern Analysis")
                            .font(.outfit(17, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Inferred from your dream language · no self-reporting")
                            .font(.outfit(10))
                            .foregroundColor(.driftTeal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var lockedView: some View {
        VStack(spacing: 20) {
            Text("🌱")
                .font(.system(size: 48))
            Text("Patterns need more dreams")
                .font(.outfit(18, weight: .semibold))
                .foregroundColor(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 6)
                    Capsule()
                        .fill(LinearGradient.driftTealPurple)
                        .frame(width: geo.size.width * CGFloat(dreams.count) / CGFloat(requiredDreams), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)

            Text("\(dreams.count) of \(requiredDreams) dreams recorded")
                .font(.outfit(13))
                .foregroundColor(.white.opacity(0.5))

            Text("Record \(requiredDreams - dreams.count) more dream\(requiredDreams - dreams.count == 1 ? "" : "s") to unlock pattern analysis.")
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text("Unlock: recurring symbols · emotional arc · dominant feelings")
                .font(.outfit(12))
                .foregroundColor(.driftTeal.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(24)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var unlockedContent: some View {
        // Insights
        ForEach(insights, id: \.title) { insight in
            HStack(spacing: 14) {
                Image(systemName: insight.icon)
                    .font(.system(size: 22))
                    .foregroundColor(.driftTeal)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.outfit(14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(insight.description)
                        .font(.outfit(13))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(16)
            .background(Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }

        // Emotional arc chart
        emotionalArcChart

        // Top symbols
        if !topSymbols.isEmpty {
            topSymbolsCard
        }
    }

    @ViewBuilder
    private var emotionalArcChart: some View {
        let abbr = Calendar.current.shortStandaloneMonthSymbols
        VStack(alignment: .leading, spacing: 12) {
            Text("Emotional Arc")
                .font(.outfit(14, weight: .semibold))
                .foregroundColor(.white)

            Chart {
                ForEach(emotionalArc, id: \.month) { point in
                    AreaMark(x: .value("Month", abbr[point.month - 1]), y: .value("Tension", point.tension))
                        .foregroundStyle(Color.driftCoral.opacity(0.5))
                    AreaMark(x: .value("Month", abbr[point.month - 1]), y: .value("Calm", point.calm))
                        .foregroundStyle(Color.driftTagGreen.opacity(0.5))
                    AreaMark(x: .value("Month", abbr[point.month - 1]), y: .value("Vivid", point.vivid))
                        .foregroundStyle(Color.white.opacity(0.25))
                    AreaMark(x: .value("Month", abbr[point.month - 1]), y: .value("Uncertain", point.uncertain))
                        .foregroundStyle(Color.driftAmber.opacity(0.5))
                }
            }
            .frame(height: 140)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .chartYAxis(.hidden)

            HStack(spacing: 16) {
                legendItem(color: .driftCoral, label: "Tension")
                legendItem(color: .driftTagGreen, label: "Calm")
                legendItem(color: .white.opacity(0.6), label: "Vivid")
                legendItem(color: .driftAmber, label: "Uncertain")
            }
            .font(.outfit(11))
        }
        .padding(16)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundColor(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var topSymbolsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Symbols")
                .font(.outfit(14, weight: .semibold))
                .foregroundColor(.white)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(topSymbols.enumerated()), id: \.offset) { item in
                    symbolBarView(item.element)
                }
            }
        }
        .padding(16)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func symbolBarView(_ sym: (symbol: String, emoji: String, count: Int)) -> some View {
        VStack(spacing: 4) {
            Text(sym.emoji).font(.system(size: 20))
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.driftPurple)
                .frame(width: 28, height: max(4, CGFloat(sym.count) * 16))
            Text(sym.symbol)
                .font(.outfit(9))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
    }
}
