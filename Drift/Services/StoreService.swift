import StoreKit
import Observation

@MainActor
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
            products = fetched.sorted { a, _ in a.id.contains("yearly") }
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

    private func checkEntitlement() async {
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
            switch result {
            case .verified(let transaction):
                await transaction.finish()
                await checkEntitlement()
            case .unverified(let transaction, _):
                await transaction.finish()
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
