public struct DefaultAddItemToBagUseCase: AddItemToBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ item: BagItem) {
        repository.save(
            bag: repository.bag.adding(item),
            notices: repository.notices.acknowledging(item.productId)
        )
    }
}
