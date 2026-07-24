public protocol GetCategoriesUseCase: Sendable {
    func execute() async -> Result<[ProductCategory], ProductError>
}

public struct DefaultGetCategoriesUseCase: GetCategoriesUseCase {
    let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func execute() async -> Result<[ProductCategory], ProductError> {
        await productRepository.getCategories()
    }
}
