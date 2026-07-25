public protocol GetProductsUseCase: Sendable {
    func callAsFunction(matching query: ProductQuery) async -> Result<[Product], ProductError>
}

public struct DefaultGetProductsUseCase: GetProductsUseCase {
    let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(matching query: ProductQuery) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(matching: query)
    }
}
