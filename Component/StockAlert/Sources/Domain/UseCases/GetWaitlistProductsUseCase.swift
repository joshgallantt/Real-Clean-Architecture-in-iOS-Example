import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what the
/// shopper is still waiting for. Not the asks — the asks include things that have already arrived —
/// but the ones the shop still has none of.
public protocol GetWaitlistProductsUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: the other half,
/// and the one the bell was tapped for.
///
/// A product stays on the waitlist when it comes back. The ask is a record of wanting to be told,
/// and whether the shop has any is a fact about the shop, not about the ask — so nothing is removed
/// on the shopper's behalf and something that sells out again simply moves back. Only
/// `SetStockAlertForProductUseCase(isOn: false)` takes something off.
public protocol GetBackInStockProductsUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

public struct DefaultGetWaitlistProductsUseCase: GetWaitlistProductsUseCase {
    private let waitlist: WaitlistProducts

    public init(repository: StockAlertRepository, lookUpProducts: LookUpProductsUseCase) {
        self.waitlist = WaitlistProducts(repository: repository, lookUpProducts: lookUpProducts)
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        await waitlist.products { !$0.availability.isAvailable }
    }
}

public struct DefaultGetBackInStockProductsUseCase: GetBackInStockProductsUseCase {
    private let waitlist: WaitlistProducts

    public init(repository: StockAlertRepository, lookUpProducts: LookUpProductsUseCase) {
        self.waitlist = WaitlistProducts(repository: repository, lookUpProducts: lookUpProducts)
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        await waitlist.products { $0.availability.isAvailable }
    }
}

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: the work both use cases do, which is the
/// same work with opposite answers to one question. Two named ports over one implementation, rather
/// than one port taking a flag and making every caller say which half it wants.
///
/// Asking the catalog is part of the rule, not something a screen does on its behalf — the same
/// arrangement `BringBagUpToDateUseCase` and `PlaceOrderUseCase` have.
private struct WaitlistProducts: Sendable {
    let repository: StockAlertRepository
    let lookUpProducts: LookUpProductsUseCase

    @MainActor
    func products(_ belongsHere: (Product) -> Bool) async -> Result<[Product], StockAlertError> {
        let waitingOn = repository.alerts.alerts.map(\.productId)
        guard !waitingOn.isEmpty else { return .success([]) }

        /// A shop that could not be reached has said nothing, and nothing is concluded from
        /// nothing. Anything it does answer about, it answers fully — so a product missing from a
        /// successful reply is one it has stopped selling, and belongs on neither list.
        guard case .success(let products) = await lookUpProducts(ids: waitingOn) else {
            return .failure(.unavailable)
        }

        return .success(products.filter(belongsHere))
    }
}
