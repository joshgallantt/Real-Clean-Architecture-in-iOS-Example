public protocol BrowseCatalogUseCase: Sendable {
    /// A page of whatever slice of the shop the shopper is looking at — everything, a
    /// category, or the words they typed.
    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError>
}

public struct DefaultBrowseCatalogUseCase: BrowseCatalogUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(matching: query)
    }
}
