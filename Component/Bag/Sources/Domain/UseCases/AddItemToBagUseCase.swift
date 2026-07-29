public protocol AddItemToBagUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

public struct DefaultAddItemToBagUseCase: AddItemToBagUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ item: BagItem) {
        repository.save(repository.bag.adding(item))
    }
}
