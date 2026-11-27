import Product

public struct DefaultSetBagItemUseCase: SetBagItemUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ item: BagItem) {
        let before = repository.bag
        let bag = before.setting(item)

        /// A line that was there and still is keeps what it is owed word about: the shopper is on
        /// the screen that shows it. A line that has just arrived starts clean, and one put back
        /// takes its notices with it — there is nothing left for them to be about.
        let stays = before.holds(productId: item.productId) && bag.holds(productId: item.productId)
        let notices = stays ? repository.notices : repository.notices.acknowledging(item.productId)

        repository.save(bag: bag, notices: notices)
    }
}
