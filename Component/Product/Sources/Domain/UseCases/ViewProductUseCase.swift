/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — everything the shop knows about one product a shopper
/// has opened.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces. Fowler, *PoEAA* (2002) —
/// Service Layer.
public protocol ViewProductUseCase: Sendable {
    func callAsFunction(id: ProductID) async -> Result<Product, ProductError>
}

public struct DefaultViewProductUseCase: ViewProductUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        await productRepository.getProduct(id: id)
    }
}
