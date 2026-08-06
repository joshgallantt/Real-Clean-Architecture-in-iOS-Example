import Product

public struct DefaultAcknowledgeNoticesUseCase: AcknowledgeNoticesUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(aboutProductId productId: ProductID) {
        repository.save(
            bag: repository.bag,
            notices: repository.notices.acknowledging(productId)
        )
    }
}
