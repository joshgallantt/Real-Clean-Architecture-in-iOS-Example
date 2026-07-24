public protocol ClearSearchHistoryUseCase: Sendable {
    func execute() async
}

public struct DefaultClearSearchHistoryUseCase: ClearSearchHistoryUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func execute() async {
        await searchHistoryRepository.clearRecentSearches()
    }
}
