public protocol BrowseCategoriesUseCase: Sendable {
    /// The ways the shop divides up what it sells, for a shopper who would rather look
    /// around than search.
    func callAsFunction() async -> Result<[ProductCategory], ProductError>
}

public struct DefaultBrowseCategoriesUseCase: BrowseCategoriesUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        await productRepository.getCategories()
    }
}
