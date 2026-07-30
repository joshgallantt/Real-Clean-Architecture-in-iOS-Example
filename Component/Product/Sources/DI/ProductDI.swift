import Product
import ProductData

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
