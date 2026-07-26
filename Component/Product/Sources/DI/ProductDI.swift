import Product
import ProductData

public struct ProductDI {
    public let getProductsUseCase: GetProductsUseCase
    public let getProductsByIdsUseCase: GetProductsByIdsUseCase
    public let getProductUseCase: GetProductUseCase
    public let getCategoriesUseCase: GetCategoriesUseCase

    public init(client: ProductClient) {
        let repository = DefaultProductRepository(client: client)
        self.getProductsUseCase = DefaultGetProductsUseCase(productRepository: repository)
        self.getProductsByIdsUseCase = DefaultGetProductsByIdsUseCase(productRepository: repository)
        self.getProductUseCase = DefaultGetProductUseCase(productRepository: repository)
        self.getCategoriesUseCase = DefaultGetCategoriesUseCase(productRepository: repository)
    }
}
