public protocol SetBagItemQuantityUseCase: Sendable {
    /// Asking for none of something is how a shopper takes it out of their bag, so this
    /// is the only way a line's count changes — including to nothing.
    @MainActor
    func callAsFunction(itemId: Int, to quantity: Int)
}

public struct DefaultSetBagItemQuantityUseCase: SetBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(itemId: Int, to quantity: Int) {
        repository.save(repository.bag.changingQuantity(ofItemId: itemId, to: quantity))
    }
}
