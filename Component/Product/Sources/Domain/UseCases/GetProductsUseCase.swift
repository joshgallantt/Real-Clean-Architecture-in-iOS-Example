public protocol GetProductsUseCase: Sendable {
    func execute(matching query: ProductQuery) async -> Result<[Product], ProductError>
}

public struct DefaultGetProductsUseCase: GetProductsUseCase {
    let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute(matching query: ProductQuery) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(matching: query)
    }
}
