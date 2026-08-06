public struct DefaultLookUpProductsUseCase: LookUpProductsUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(ids: ids)
    }
}
