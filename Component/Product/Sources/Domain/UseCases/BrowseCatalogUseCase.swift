/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — a page of whatever slice of the shop the shopper is
/// looking at.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol BrowseCatalogUseCase: Sendable {
    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: a shop does not offer what it has
/// stopped selling. That is a rule about the shop, so it is applied once here rather than left as a
/// filter every grid, search and category screen has to remember — and one that a new screen would
/// be free to forget.
///
/// Only browsing is filtered. `LookUpProductsUseCase` still answers about anything, because the
/// lists it fills in are ones the shopper already holds, and a bag has to be able to say what left
/// it.
public struct DefaultBrowseCatalogUseCase: BrowseCatalogUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await productRepository
            .getProducts(matching: query)
            .map { $0.filter { $0.availability != .discontinued } }
    }
}
