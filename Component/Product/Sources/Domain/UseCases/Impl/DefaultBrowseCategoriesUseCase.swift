/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — the ways the shop divides up what it sells, for a
/// shopper who would rather look than search.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol BrowseCategoriesUseCase: Sendable {
    func callAsFunction() async -> Result<[ProductCategory], ProductError>
}

public struct DefaultBrowseCategoriesUseCase: BrowseCategoriesUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        await productRepository.getCategories()
    }
}
