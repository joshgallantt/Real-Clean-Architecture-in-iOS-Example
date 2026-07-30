public protocol LookUpProductsUseCase: Sendable {
    /// What the shop currently says about products the shopper already has a hold of.
    ///
    /// This is what a bag and a wishlist are for: both keep nothing but identities, and both
    /// need names, pictures, prices and availability filled in before they can be shown or
    /// brought up to date. Products the shop no longer has are absent from the answer rather
    /// than failing it — a delisted product is a fact about that product, not about the
    /// request.
    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError>
}

public struct DefaultLookUpProductsUseCase: LookUpProductsUseCase {
    private let productRepository: ProductRepository

    public init(productRepository: ProductRepository) {
        self.productRepository = productRepository
    }

    public func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await productRepository.getProducts(ids: ids)
    }
}
