public protocol ViewProductUseCase: Sendable {
    /// Everything the shop knows about one product, for a shopper who has opened it.
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
