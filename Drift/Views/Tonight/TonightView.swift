import SwiftUI
import SwiftData

struct TonightView: View {
    @Binding var selectedTab: ContentView.Tab
    @Query(sort: \Dream.date, order: .reverse) private var dreams: [Dream]
    @State private var showSettings = false
    @State private var showYearInDreams = false
    @State private var selectedDream: Dream?

    var body: some View {
        ZStack {
            Color.driftBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header row — logo + settings
                    HStack {
                        Text("drift.")
                            .font(.cormorant(44, weight: .bold, italic: true))
                            .foregroundStyle(LinearGradient.driftTealPurple)

                        Spacer()

                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.driftPurple)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 8)

                    MoonPhaseCard()

                    RecordCTACard {
                        selectedTab = .record
                    }

                    YearInDreamsTeaser {
                        showYearInDreams = true
                    }

                    if !dreams.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Dreams")
                                .font(.outfit(16, weight: .semibold))
                                .foregroundColor(.white)

                            ForEach(dreams.prefix(5)) { dream in
                                Button {
                                    selectedDream = dream
                                } label: {
                                    RecentDreamCard(dream: dream)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showYearInDreams) {
            YearInDreamsView()
        }
        .sheet(item: $selectedDream) { dream in
            ReflectionView(dream: dream, isReadOnly: true)
        }
    }
}

struct RecentDreamCard: View {
    let dream: Dream

    var body: some View {
        HStack(spacing: 12) {
            Text(dream.emojis.prefix(3).joined())
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(dream.title)
                    .font(.cormorant(18, weight: .semibold, italic: true))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(dream.shortDate)
                    .font(.outfit(12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text("\(dream.vividness)")
                .font(.outfit(20, weight: .bold))
                .foregroundColor(.driftCoral)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
