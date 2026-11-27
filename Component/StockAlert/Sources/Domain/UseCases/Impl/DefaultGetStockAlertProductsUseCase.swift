import Product

/// Asking the catalog is part of the rule, not something a screen does on its behalf — the same
/// arrangement `CheckBagUseCase` and `PlaceOrderUseCase` have.
public struct DefaultGetStockAlertProductsUseCase: GetStockAlertProductsUseCase {
    private let repository: StockAlertRepository
    private let lookUpProducts: LookUpProductsUseCase

    public init(repository: StockAlertRepository, lookUpProducts: LookUpProductsUseCase) {
        self.repository = repository
        self.lookUpProducts = lookUpProducts
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], StockAlertError> {
        let alertedOn = repository.stockAlerts.items.map(\.productId)
        guard !alertedOn.isEmpty else { return .success([]) }

        /// A shop that could not be reached has said nothing, and nothing is concluded from
        /// nothing. Anything it does answer about, it answers fully — so a product missing from a
        /// successful reply is one it has stopped selling, and there is nothing left to alert on.
        guard case .success(let products) = await lookUpProducts(ids: alertedOn) else {
            return .failure(.unavailable)
        }

        /// What the bell was rung for comes first: the products that are back. The rest follow,
        /// each group in the order the shop answered in.
        return .success(
            products.filter(\.availability.isAvailable) + products.filter { !$0.availability.isAvailable }
        )
    }
}
