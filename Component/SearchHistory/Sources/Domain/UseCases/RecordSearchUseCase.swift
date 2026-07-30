import Product

public protocol RecordSearchUseCase: Sendable {
    /// Remembers a search the shopper actually ran. Takes a `SearchTerm`, so there is no
    /// blank-or-not decision left for a caller to make differently.
    func callAsFunction(_ term: SearchTerm) async
}

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ term: SearchTerm) async {
        await repository.save(await repository.history().recording(term))
    }
}
