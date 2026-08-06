import Product

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ term: SearchTerm) {
        repository.save(repository.history().recording(term))
    }
}
