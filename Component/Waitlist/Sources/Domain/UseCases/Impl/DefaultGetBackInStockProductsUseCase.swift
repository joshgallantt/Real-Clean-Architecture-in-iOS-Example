import Product

public struct DefaultGetBackInStockProductsUseCase: GetBackInStockProductsUseCase {
    private let waitlisted: WaitlistedProducts

    public init(repository: WaitlistRepository, lookUpProducts: LookUpProductsUseCase) {
        self.waitlisted = WaitlistedProducts(repository: repository, lookUpProducts: lookUpProducts)
    }

    @MainActor
    public func callAsFunction() async -> Result<[Product], WaitlistError> {
        await waitlisted.products { $0.availability.isAvailable }
    }
}
