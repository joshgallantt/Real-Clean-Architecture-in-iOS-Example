public protocol AddItemToBagUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

public struct DefaultAddItemToBagUseCase: AddItemToBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    /// Choosing something is also seeing its price and its availability, so anything
    /// waiting to be said about it has already served its purpose.
    @MainActor
    public func callAsFunction(_ item: BagItem) {
        repository.save(
            bag: repository.bag.adding(item),
            changes: repository.changes.acknowledging(productId: item.productId)
        )
    }
}
