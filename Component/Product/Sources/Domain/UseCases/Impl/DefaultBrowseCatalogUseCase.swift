/// A shop does not offer what it has stopped selling. That is a payload the repository never hands
/// over rather than a filter here — one place instead of two, and browsing and looking up by id
/// agree by construction rather than by both remembering the same rule.
public struct DefaultBrowseCatalogUseCase: BrowseCatalogUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(matching: query)
    }
}
