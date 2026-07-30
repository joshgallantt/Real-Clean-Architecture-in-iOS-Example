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

    public init(client: ProductClient) {
        let repository = DefaultProductRepository(client: client)
        self.browseCatalogUseCase = DefaultBrowseCatalogUseCase(productRepository: repository)
        self.lookUpProductsUseCase = DefaultLookUpProductsUseCase(productRepository: repository)
        self.viewProductUseCase = DefaultViewProductUseCase(productRepository: repository)
        self.browseCategoriesUseCase = DefaultBrowseCategoriesUseCase(productRepository: repository)
    }
}
