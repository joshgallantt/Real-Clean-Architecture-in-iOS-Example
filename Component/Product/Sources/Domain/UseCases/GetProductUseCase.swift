public protocol GetProductUseCase: Sendable {
    func execute(id: Int) async -> Result<Product, ProductError>
}

public struct DefaultGetProductUseCase: GetProductUseCase {
    let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute(id: Int) async -> Result<Product, ProductError> {
        await productRepository.getProduct(id: id)
    }
}
