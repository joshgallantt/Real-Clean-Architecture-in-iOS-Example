/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — a page of whatever slice of the shop the shopper is
/// looking at.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol BrowseCatalogUseCase: Sendable {
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
