/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — filling in the things on a list the shopper already
/// holds — a bag or a wishlist keeps ids alone.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol LookUpProductsUseCase: Sendable {
    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError>
}

public struct DefaultLookUpProductsUseCase: LookUpProductsUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(ids: ids)
    }
}
