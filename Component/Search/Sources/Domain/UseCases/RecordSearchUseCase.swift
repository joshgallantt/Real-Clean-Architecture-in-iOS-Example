public protocol RecordSearchUseCase: Sendable {
    func callAsFunction(_ query: String) async
}

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func callAsFunction(_ query: String) async {
        await searchHistoryRepository.recordSearch(query)
    }
}
