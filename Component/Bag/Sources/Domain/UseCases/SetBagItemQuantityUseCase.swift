import Product

public protocol SetBagItemQuantityUseCase: Sendable {
    /// Asking for none of something is how a shopper takes it out of their bag, so this
    /// is the only way a line's count changes — including to nothing.
    @MainActor
    func callAsFunction(productId: ProductID, to quantity: Int)
}

public struct DefaultSetBagItemQuantityUseCase: SetBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID, to quantity: Int) {
        let bag = repository.bag.changingQuantity(of: productId, to: quantity)

        // A price move about a line the shopper has just taken out is news about
        // nothing, so it goes with it.
        let changes = bag.holds(productId: productId)
            ? repository.changes
            : repository.changes.acknowledging(productId: productId)

        repository.save(bag: bag, changes: changes)
    }
}
