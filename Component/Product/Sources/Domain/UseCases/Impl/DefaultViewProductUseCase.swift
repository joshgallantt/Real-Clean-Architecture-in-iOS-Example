/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an application-specific rule,
/// named for what a shopper is trying to do — everything the shop knows about one product a shopper
/// has opened.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces. Fowler, *PoEAA*
/// (2002), Ch. 9 — Service Layer.
public protocol ViewProductUseCase: Sendable {
    func callAsFunction(id: ProductID) async -> Result<Product, ProductError>
}

public struct DefaultViewProductUseCase: ViewProductUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    /// Something the shop has stopped selling has no page, and a link to one — from a bookmark, a
    /// share, a stale search result — is `.notFound`. It reads as a plain pass-through because the
    /// repository has already decided that: a product it will not hand over and a product that was
    /// never there answer identically, which is the whole point of deciding it there.
    public func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        await productRepository.getProduct(id: id)
    }
}
