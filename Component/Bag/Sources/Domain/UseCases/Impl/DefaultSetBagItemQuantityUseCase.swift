import Product

public struct DefaultSetBagItemQuantityUseCase: SetBagItemQuantityUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID, to quantity: Int) {
        let bag = repository.bag.changingQuantity(of: productId, to: quantity)

        /// A line the shopper has put back takes its notices with it — there is nothing left on the
        /// screen for them to be about.
        let notices = bag.holds(productId: productId)
            ? repository.notices
            : repository.notices.acknowledging(productId)

        repository.save(bag: bag, notices: notices)
    }
}
