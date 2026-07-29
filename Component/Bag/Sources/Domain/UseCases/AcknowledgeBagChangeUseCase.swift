public protocol AcknowledgeBagChangeUseCase: Sendable {
    /// The shopper has seen what happened to this line and is keeping it.
    @MainActor
    func callAsFunction(itemId: Int)
}

public struct DefaultAcknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(itemId: Int) {
        repository.save(repository.bag.acknowledging(itemId: itemId))
    }
}
