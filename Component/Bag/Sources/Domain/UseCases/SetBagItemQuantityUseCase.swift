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
        let bag = repository.bag.changingQuantity(ofItemId: itemId, to: quantity)

        // A price warning about a line the shopper has just taken out is a warning about
        // nothing, so it goes with it.
        let changes = bag.quantity(forItemId: itemId) == 0
            ? repository.changes.acknowledging(itemId: itemId)
            : repository.changes

        repository.save(bag: bag, changes: changes)
    }
}
