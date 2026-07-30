import Product
import ProductData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct ProductDI {
    public let browseCatalogUseCase: BrowseCatalogUseCase
    public let lookUpProductsUseCase: LookUpProductsUseCase
    public let viewProductUseCase: ViewProductUseCase
    public let browseCategoriesUseCase: BrowseCategoriesUseCase

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the use cases
    /// are named by their port, so the app layer may supply any repository — the real one, or one
    /// wrapped in something. Every use case here is built on the same instance, so whatever is
    /// handed in answers all four of them and cannot answer two of them differently.
    public init(repository: ProductRepository) {
        self.browseCatalogUseCase = DefaultBrowseCatalogUseCase(productRepository: repository)
        self.lookUpProductsUseCase = DefaultLookUpProductsUseCase(productRepository: repository)
        self.viewProductUseCase = DefaultViewProductUseCase(productRepository: repository)
        self.browseCategoriesUseCase = DefaultBrowseCategoriesUseCase(productRepository: repository)
    }

    public init(client: ProductClient) {
        self.init(repository: DefaultProductRepository(client: client))
    }
}
