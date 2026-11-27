public struct DefaultSetBagItemUseCase: SetBagItemUseCase {
    private let repository: BagRepository

    public init(repository: BagRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ item: BagItem) {
        repository.save(repository.bag.setting(item))
    }
}
