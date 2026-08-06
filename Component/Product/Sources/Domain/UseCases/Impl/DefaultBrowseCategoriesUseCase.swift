public struct DefaultBrowseCategoriesUseCase: BrowseCategoriesUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        await productRepository.getCategories()
    }
}
