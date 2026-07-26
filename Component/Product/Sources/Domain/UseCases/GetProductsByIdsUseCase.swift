public protocol GetProductsByIdsUseCase: Sendable {
    func callAsFunction(ids: [Int]) async -> Result<[Product], ProductError>
}

public struct DefaultGetProductsByIdsUseCase: GetProductsByIdsUseCase {
    let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(ids: [Int]) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(ids: ids)
    }
}
