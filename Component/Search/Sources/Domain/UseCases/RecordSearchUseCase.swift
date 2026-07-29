public protocol RecordSearchUseCase: Sendable {
    func callAsFunction(_ query: String) async
}

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ query: String) async {
        await repository.save(await repository.history().recording(query))
    }
}
