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
