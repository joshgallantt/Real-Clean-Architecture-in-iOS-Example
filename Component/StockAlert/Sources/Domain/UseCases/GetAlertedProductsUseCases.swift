import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what a shopper
/// is *still waiting on*. It is not a set of alerts and it is not a list of products — it is the
/// asks the shop has not answered yet, which needs both to work out.
public protocol GetProductsToBeNotifiedUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: the other half,
/// and the one the bell was tapped for. Told apart from the list above by what the shop stocks
/// today, so something moves between them the moment it returns.
public protocol GetBackInStockProductsUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

public struct DefaultGetProductsToBeNotifiedUseCase: GetProductsToBeNotifiedUseCase {
    private let alerted: AlertedProducts

    public init(repository: StockAlertRepository, lookUpProducts: LookUpProductsUseCase) {
        self.alerted = AlertedProducts(repository: repository, lookUpProducts: lookUpProducts)
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        await alerted.products { !$0.availability.isAvailable }
    }
}

public struct DefaultGetBackInStockProductsUseCase: GetBackInStockProductsUseCase {
    private let alerted: AlertedProducts

    public init(repository: StockAlertRepository, lookUpProducts: LookUpProductsUseCase) {
        self.alerted = AlertedProducts(repository: repository, lookUpProducts: lookUpProducts)
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        await alerted.products { $0.availability.isAvailable }
    }
}

/// Evans, *Domain-Driven Design* (2003), Ch. 5 — Services: the work both use cases do, which is the
/// same work with opposite answers to one question. Two named ports over one implementation, rather
/// than one port that takes a flag and makes every caller say which half it wants.
///
/// Asking the catalog is part of the rule, not something a screen does on its behalf — the same
/// arrangement `BringBagUpToDateUseCase` and `PlaceOrderUseCase` have.
private struct AlertedProducts: Sendable {
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
