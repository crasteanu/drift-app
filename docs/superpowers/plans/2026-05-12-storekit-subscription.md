# StoreKit Subscription System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a freemium subscription system — 7 free AI interpretations then Pro required, Patterns tab gated behind Pro.

**Architecture:** `StoreService` (`@Observable`) owns all StoreKit 2 logic and is injected via SwiftUI environment. An `@AppStorage` counter tracks free interpretations; it is checked in `RecordView` and `DreamEditView` before calling Claude. `PatternsView` is fully locked for non-subscribers via a tab-bar interceptor in `DriftTabBar`.

**Tech Stack:** StoreKit 2 (iOS 17+, async/await), SwiftUI `@Observable`, `@AppStorage`, `@Environment`

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `Drift/Services/StoreService.swift` | Product loading, purchase, entitlement |
| Create | `Drift/Views/Subscription/PaywallView.swift` | Full-screen paywall sheet + context enum |
| Create | `Drift/Configuration/DriftStoreKit.storekit` | Local StoreKit sandbox products |
| Modify | `Drift/DriftApp.swift` | Inject StoreService, start Transaction.updates |
| Modify | `Drift/Views/ContentView.swift` | Pass lock state to DriftTabBar, show paywall |
| Modify | `Drift/Views/Patterns/PatternsView.swift` | Subscription-gated placeholder |
| Modify | `Drift/Views/Record/RecordView.swift` | Usage gate + free-count badge |
| Modify | `Drift/Views/Journal/DreamEditView.swift` | Usage gate on re-interpret |
| Modify | `Drift/Views/Settings/SettingsView.swift` | Subscription status section |

---

## Task 1: StoreKit sandbox configuration file

**Files:**
- Create: `Drift/Configuration/DriftStoreKit.storekit`

- [ ] **Step 1: Create the StoreKit configuration file**

Create the file at `Drift/Configuration/DriftStoreKit.storekit` with this exact content:

```json
{
  "identifier" : "DriftStoreKit",
  "nonRenewingSubscriptions" : [],
  "products" : [],
  "settings" : {
    "_locale" : "en_US",
    "_storefront" : "USA",
    "_storeKitErrors" : []
  },
  "subscriptionGroups" : [
    {
      "id" : "group.drift.pro",
      "localizations" : [],
      "name" : "Drift Pro",
      "subscriptions" : [
        {
          "adHocOffers" : [],
          "displayPrice" : "2.99",
          "familyShareable" : false,
          "groupNumber" : 1,
          "internalID" : "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "Unlimited dream interpretations and pattern analysis",
              "displayName" : "Drift Pro Monthly",
              "locale" : "en_US"
            }
          ],
          "productID" : "com.driftapp.pro.monthly",
          "recurringSubscriptionPeriod" : "P1M",
          "referenceName" : "Drift Pro Monthly",
          "subscriptionGroupID" : "group.drift.pro",
          "type" : "RecurringSubscription"
        },
        {
          "adHocOffers" : [],
          "displayPrice" : "19.99",
          "familyShareable" : false,
          "groupNumber" : 2,
          "internalID" : "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
          "introductoryOffer" : null,
          "localizations" : [
            {
              "description" : "Unlimited dream interpretations and pattern analysis",
              "displayName" : "Drift Pro Yearly",
              "locale" : "en_US"
            }
          ],
          "productID" : "com.driftapp.pro.yearly",
          "recurringSubscriptionPeriod" : "P1Y",
          "referenceName" : "Drift Pro Yearly",
          "subscriptionGroupID" : "group.drift.pro",
          "type" : "RecurringSubscription"
        }
      ]
    }
  ],
  "version" : {
    "major" : 2,
    "minor" : 0
  }
}
```

- [ ] **Step 2: Add the file to the Xcode project**

In Xcode: File → Add Files to "Drift" → select `Drift/Configuration/DriftStoreKit.storekit`. Ensure it is added to the **Drift** target.

- [ ] **Step 3: Enable StoreKit testing in the scheme**

In Xcode: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → select `DriftStoreKit.storekit`.

- [ ] **Step 4: Commit**

```bash
git add Drift/Configuration/DriftStoreKit.storekit
git commit -m "feat: add StoreKit sandbox configuration for Drift Pro subscriptions"
```

---

## Task 2: StoreService

**Files:**
- Create: `Drift/Services/StoreService.swift`

- [ ] **Step 1: Create StoreService**

Create `Drift/Services/StoreService.swift`:

```swift
import StoreKit
import Observation

@Observable
final class StoreService {
    private(set) var products: [Product] = []
    private(set) var isSubscribed: Bool = false

    private let productIDs: Set<String> = [
        "com.driftapp.pro.monthly",
        "com.driftapp.pro.yearly"
    ]

    func load() async {
        await checkEntitlement()
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched.sorted { _, b in b.id.contains("monthly") }
        } catch {
            // products stays empty; paywall shows retry state
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlement()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkEntitlement()
    }

    func checkEntitlement() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               productIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasActive = true
                break
            }
        }
        isSubscribed = hasActive
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
                await checkEntitlement()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? { "Purchase verification failed" }
}
```

- [ ] **Step 2: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Drift/Services/StoreService.swift
git commit -m "feat: add StoreService for StoreKit 2 subscription management"
```

---

## Task 3: PaywallView

**Files:**
- Create: `Drift/Views/Subscription/PaywallView.swift`

- [ ] **Step 1: Create the Subscription folder and PaywallView**

Create `Drift/Views/Subscription/PaywallView.swift`:

```swift
import SwiftUI
import StoreKit

enum PaywallContext {
    case interpretationLimit
    case patternsLock

    var subtitle: String {
        switch self {
        case .interpretationLimit:
            return "You've used your 7 free interpretations. Subscribe to keep exploring."
        case .patternsLock:
            return "Unlock pattern analysis and unlimited interpretations."
        }
    }
}

struct PaywallView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss

    let context: PaywallContext

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.driftBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection
                        featuresCard
                        if store.products.isEmpty {
                            retryButton
                        } else {
                            planCards
                        }
                        ctaButton
                        footerLinks
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
        .onChange(of: store.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
        .onAppear {
            selectedProduct = store.products.first { $0.id.contains("yearly") }
                ?? store.products.first
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 10) {
            Text("🌙")
                .font(.system(size: 52))
            Text("Your dreams go deeper.")
                .font(.cormorant(26, weight: .bold, italic: true))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Text(context.subtitle)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 12)
    }

    private var featuresCard: some View {
        VStack(spacing: 0) {
            featureRow(icon: "infinity", text: "Unlimited interpretations")
            Divider().background(Color.white.opacity(0.08))
            featureRow(icon: "sparkles", text: "Dream pattern analysis")
            Divider().background(Color.white.opacity(0.08))
            featureRow(icon: "star.fill", text: "Full symbol library")
        }
        .background(Color.driftCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.driftTeal)
                .frame(width: 24)
            Text(text)
                .font(.outfit(14))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var planCards: some View {
        HStack(spacing: 10) {
            ForEach(store.products, id: \.id) { product in
                planCard(for: product)
            }
        }
    }

    private func planCard(for product: Product) -> some View {
        let isYearly = product.id.contains("yearly")
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProduct = product
        } label: {
            VStack(spacing: 6) {
                if isYearly {
                    Text("BEST VALUE")
                        .font(.outfit(9, weight: .bold))
                        .foregroundColor(.driftTeal)
                } else {
                    Text(" ").font(.outfit(9))
                }
                Text(isYearly ? "Yearly" : "Monthly")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.white)
                Text(product.displayPrice)
                    .font(.outfit(20, weight: .bold))
                    .foregroundColor(.white)
                Text(isYearly ? monthlyBreakdown(for: product) : "per month")
                    .font(.outfit(10))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.driftPurple : Color.driftCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.driftPurple : Color.driftPurple.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func monthlyBreakdown(for product: Product) -> String {
        let monthly = product.price / 12
        return product.priceFormatStyle.format(monthly) + "/mo"
    }

    private var retryButton: some View {
        Button {
            Task { await store.load() }
        } label: {
            Text("Retry loading plans")
                .font(.outfit(14))
                .foregroundColor(.driftTeal)
        }
    }

    private var ctaButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            isPurchasing = true
            Task {
                do {
                    try await store.purchase(product)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isPurchasing = false
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Subscribe")
                        .font(.outfit(16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                store.products.isEmpty || selectedProduct == nil
                    ? Color.driftCard
                    : Color.driftPurple
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedProduct == nil || isPurchasing || store.products.isEmpty)
        .buttonStyle(.plain)
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Button {
                isRestoring = true
                Task {
                    do {
                        try await store.restorePurchases()
                        if !store.isSubscribed {
                            errorMessage = "No active subscription found."
                            showError = true
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                    isRestoring = false
                }
            } label: {
                Group {
                    if isRestoring {
                        ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.7)
                    } else {
                        Text("Restore purchases")
                    }
                }
            }
            Text("·").foregroundColor(.white.opacity(0.15))
            Link("Privacy", destination: URL(string: "https://claudiualina.com/drift-privacy")!)
        }
        .font(.outfit(11))
        .foregroundColor(.white.opacity(0.35))
    }
}
```

- [ ] **Step 2: Add the file to the Xcode project**

In Xcode: File → Add Files to "Drift" → select `Drift/Views/Subscription/PaywallView.swift`. Ensure it is added to the **Drift** target.

- [ ] **Step 3: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Drift/Views/Subscription/PaywallView.swift
git commit -m "feat: add PaywallView with yearly/monthly plan cards and context-aware messaging"
```

---

## Task 4: Inject StoreService in DriftApp

**Files:**
- Modify: `Drift/DriftApp.swift`

- [ ] **Step 1: Add StoreService state and inject into environment**

Open `Drift/DriftApp.swift`. The current file is:

```swift
import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    private let container: ModelContainer = { ... }()

    init() { ... }

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
```

Add `@State private var storeService = StoreService()` after the `hasSeenWelcome` line, and update the `body` to inject the service and start both tasks:

```swift
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
```

- [ ] **Step 2: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Drift/DriftApp.swift
git commit -m "feat: inject StoreService into environment and start transaction listener"
```

---

## Task 5: ContentView + DriftTabBar — Patterns lock

**Files:**
- Modify: `Drift/Views/ContentView.swift`

- [ ] **Step 1: Update DriftTabBar to accept lock state and intercept taps**

`DriftTabBar` is defined at the bottom of `Drift/Views/ContentView.swift`. Replace the entire `DriftTabBar` struct with:

```swift
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
```

- [ ] **Step 2: Update ContentView to read StoreService and wire the paywall**

Replace the entire `ContentView` struct with:

```swift
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
```

- [ ] **Step 3: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Drift/Views/ContentView.swift
git commit -m "feat: lock Patterns tab with badge and paywall for non-subscribers"
```

---

## Task 6: PatternsView — subscription-gated placeholder

**Files:**
- Modify: `Drift/Views/Patterns/PatternsView.swift`

- [ ] **Step 1: Add StoreService environment and subscription gate**

At the top of `PatternsView`, add the `StoreService` environment property and a `showPaywall` state. Then wrap the existing content with a subscription check.

Add to `PatternsView` properties (after `@State private var showMoreInfo = false`):

```swift
@Environment(StoreService.self) private var storeService
@State private var showPaywall = false
```

Replace the `body` computed property with:

```swift
var body: some View {
    NavigationStack {
        ZStack {
            Color.driftBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if !storeService.isSubscribed {
                        proLockedView
                    } else {
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
                        .font(.cormorant(28, weight: .bold, italic: true))
                        .foregroundStyle(LinearGradient.driftTealPurple)
                    Text("Inferred from your dream language · no self-reporting")
                        .font(.outfit(12))
                        .foregroundColor(.driftTeal)
                }
            }
        }
    }
    .fullScreenCover(isPresented: $showPaywall) {
        PaywallView(context: .patternsLock)
    }
}
```

Add the `proLockedView` computed property to `PatternsView` (alongside the existing `lockedView`):

```swift
@ViewBuilder
private var proLockedView: some View {
    VStack(spacing: 20) {
        Text("🔒")
            .font(.system(size: 48))
        Text("Patterns is Pro")
            .font(.outfit(18, weight: .semibold))
            .foregroundColor(.white)
        Text("Discover recurring symbols, themes, and emotions across your entire dream journal.")
            .font(.outfit(14))
            .foregroundColor(.white.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
        Button {
            showPaywall = true
        } label: {
            Text("Unlock with Pro")
                .font(.outfit(15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.driftPurple)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
    .padding(24)
    .background(Color.driftCard)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}
```

- [ ] **Step 2: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Drift/Views/Patterns/PatternsView.swift
git commit -m "feat: gate PatternsView behind Pro subscription with locked placeholder"
```

---

## Task 7: RecordView — usage gate and free-count badge

**Files:**
- Modify: `Drift/Views/Record/RecordView.swift`

- [ ] **Step 1: Add StoreService, interpretation counter, and paywall state**

Add to `RecordView` properties (after `@AppStorage("whisperLanguage")`):

```swift
@Environment(StoreService.self) private var storeService
@AppStorage("interpretationCount") private var interpretationCount: Int = 0
@State private var showPaywall = false
```

- [ ] **Step 2: Add the usage gate to interpretDream()**

Replace the existing `interpretDream()` function with:

```swift
private func interpretDream() async {
    guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        error = "No transcript to interpret."
        processingState = .idle
        return
    }

    if !storeService.isSubscribed && interpretationCount >= 7 {
        showPaywall = true
        return
    }

    withAnimation { processingState = .interpreting }
    do {
        let result = try await ClaudeService.interpret(
            transcript: transcript,
            mode: mode,
            previousDreams: Array(dreams.prefix(3)),
            language: language
        )
        interpretation = result
        saveDream(from: result)
        interpretationCount += 1
        withAnimation { processingState = .done }
    } catch {
        let msg = error.localizedDescription
        self.error = "Interpretation failed: \(msg)"
        withAnimation { processingState = .error(msg) }
    }
}
```

- [ ] **Step 3: Add free-count badge above the Interpret button**

In `transcribedView`, the interpret button currently reads:

```swift
Button {
    Task { await interpretDream() }
} label: {
    HStack(spacing: 8) {
        Image(systemName: "sparkles")
        Text("Interpret Dream")
            .font(.outfit(16, weight: .semibold))
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 18)
    .background(
        LinearGradient(colors: [.driftPurple, .driftPurpleDark], startPoint: .leading, endPoint: .trailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
}
```

Replace that button (and nothing else in `transcribedView`) with:

```swift
if !storeService.isSubscribed && interpretationCount < 7 {
    Text("\(7 - interpretationCount) free interpretation\(7 - interpretationCount == 1 ? "" : "s") left")
        .font(.outfit(12))
        .foregroundColor(.driftAmber)
}

Button {
    Task { await interpretDream() }
} label: {
    HStack(spacing: 8) {
        Image(systemName: "sparkles")
        Text("Interpret Dream")
            .font(.outfit(16, weight: .semibold))
    }
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 18)
    .background(
        LinearGradient(colors: [.driftPurple, .driftPurpleDark], startPoint: .leading, endPoint: .trailing)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
}
```

- [ ] **Step 4: Wire fullScreenCover into RecordView body**

In `RecordView.body`, add `.fullScreenCover` after the `.onDisappear` modifier:

```swift
.fullScreenCover(isPresented: $showPaywall) {
    PaywallView(context: .interpretationLimit)
}
```

- [ ] **Step 5: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add Drift/Views/Record/RecordView.swift
git commit -m "feat: add interpretation usage gate and free-count badge to RecordView"
```

---

## Task 8: DreamEditView — usage gate on re-interpret

**Files:**
- Modify: `Drift/Views/Journal/DreamEditView.swift`

- [ ] **Step 1: Add StoreService, interpretation counter, and paywall state**

Add to `DreamEditView` properties (after `@AppStorage("whisperLanguage")`):

```swift
@Environment(StoreService.self) private var storeService
@AppStorage("interpretationCount") private var interpretationCount: Int = 0
@State private var showPaywall = false
```

- [ ] **Step 2: Add the usage gate to reinterpret()**

Replace the existing `reinterpret()` function with:

```swift
private func reinterpret() async {
    if !storeService.isSubscribed && interpretationCount >= 7 {
        showPaywall = true
        return
    }

    errorMessage = nil
    let previous = allDreams.filter { $0.id != dream.id }.prefix(3)
    withAnimation { isInterpreting = true }
    do {
        let result = try await ClaudeService.interpret(
            transcript: transcript,
            mode: mode,
            previousDreams: Array(previous),
            language: language
        )
        interpretationCount += 1
        withAnimation {
            isInterpreting = false
            pendingInterpretation = result
        }
    } catch {
        withAnimation { isInterpreting = false }
        errorMessage = "Re-interpretation failed: \(error.localizedDescription)"
    }
}
```

- [ ] **Step 3: Wire fullScreenCover into DreamEditView body**

In `DreamEditView.body`, the `NavigationStack` currently ends with `.onAppear`. Add `.fullScreenCover` after it:

```swift
.fullScreenCover(isPresented: $showPaywall) {
    PaywallView(context: .interpretationLimit)
}
```

- [ ] **Step 4: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Drift/Views/Journal/DreamEditView.swift
git commit -m "feat: add interpretation usage gate to DreamEditView re-interpret flow"
```

---

## Task 9: SettingsView — subscription status section

**Files:**
- Modify: `Drift/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Add StoreService environment and paywall state**

Add to `SettingsView` properties (after `@Query private var dreams`):

```swift
@Environment(StoreService.self) private var storeService
@State private var showPaywall = false
@State private var isRestoring = false
```

- [ ] **Step 2: Add the subscription section at the top of the List**

In `SettingsView.body`, the `List` currently starts with the Voice language section. Add the subscription section before it:

```swift
// Subscription
Section {
    if storeService.isSubscribed {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("drift pro")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Active")
                    .font(.outfit(12))
                    .foregroundColor(.driftTeal)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.driftTeal)
                .font(.system(size: 18))
        }
        .listRowBackground(Color.driftCard)

        Button {
            UIApplication.shared.open(
                URL(string: "https://apps.apple.com/account/subscriptions")!
            )
        } label: {
            Label("Manage Subscription", systemImage: "arrow.up.right")
                .font(.outfit(14))
                .foregroundColor(.white)
        }
        .listRowBackground(Color.driftCard)
    } else {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Free Plan")
                    .font(.outfit(14, weight: .semibold))
                    .foregroundColor(.white)
                let used = min(interpretationCount, 7)
                let remaining = max(0, 7 - interpretationCount)
                Text("\(used) used · \(remaining) left")
                    .font(.outfit(12))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .listRowBackground(Color.driftCard)

        Button {
            showPaywall = true
        } label: {
            Label("Unlock Pro", systemImage: "sparkles")
                .font(.outfit(14, weight: .medium))
                .foregroundColor(.driftPurple)
        }
        .listRowBackground(Color.driftCard)

        Button {
            isRestoring = true
            Task {
                try? await storeService.restorePurchases()
                isRestoring = false
            }
        } label: {
            HStack {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .font(.outfit(14))
                    .foregroundColor(.white)
                Spacer()
                if isRestoring { ProgressView().tint(.white) }
            }
        }
        .listRowBackground(Color.driftCard)
        .disabled(isRestoring)
    }
} header: {
    Text("Subscription")
        .font(.outfit(13, weight: .semibold))
        .foregroundColor(.white.opacity(0.4))
}
```

Note: `interpretationCount` is not currently a property of `SettingsView`. Add it with the other properties:

```swift
@AppStorage("interpretationCount") private var interpretationCount: Int = 0
```

- [ ] **Step 3: Add fullScreenCover to SettingsView body**

At the end of the `NavigationStack` in `SettingsView.body` (after the last `.sheet` modifier), add:

```swift
.fullScreenCover(isPresented: $showPaywall) {
    PaywallView(context: .interpretationLimit)
}
```

- [ ] **Step 4: Verify the file builds**

```bash
xcodebuild build \
  -project /Users/claudiurasteanu/Documents/Drift/Drift.xcodeproj \
  -scheme Drift \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Drift/Views/Settings/SettingsView.swift
git commit -m "feat: add subscription status section to SettingsView"
```

---

## Task 10: Manual smoke test

Run the app in the simulator with the StoreKit configuration active.

- [ ] **Verify free gate:** Reset `interpretationCount` to 6 in UserDefaults (Simulator → Device → App Settings, or add a debug reset button temporarily). Record and interpret a 7th dream — succeeds. Attempt an 8th — paywall appears.
- [ ] **Verify paywall:** Both plan cards load with prices. Selecting yearly highlights it. Tapping Subscribe triggers the StoreKit sandbox purchase sheet. After purchase, paywall dismisses automatically and the badge on the Patterns tab disappears.
- [ ] **Verify Patterns lock:** With no subscription, Patterns tab shows amber lock badge. Tapping opens paywall with "Unlock pattern analysis..." subtitle. After subscribing, badge gone and Patterns loads normally.
- [ ] **Verify restore:** Log out of sandbox account, reinstall. Tap "Restore purchases" in Settings — subscription is recovered.
- [ ] **Verify Settings section:** Free state shows correct used/remaining count. Subscribed state shows "drift pro · Active" and Manage Subscription link.
