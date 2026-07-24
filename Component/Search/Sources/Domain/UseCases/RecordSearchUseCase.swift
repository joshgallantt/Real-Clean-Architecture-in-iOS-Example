public protocol RecordSearchUseCase: Sendable {
    func execute(_ query: String) async
}

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func execute(_ query: String) async {
        await searchHistoryRepository.recordSearch(query)
    }
}
