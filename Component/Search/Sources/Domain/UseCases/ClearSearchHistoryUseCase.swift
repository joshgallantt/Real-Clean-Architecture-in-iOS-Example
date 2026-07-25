public protocol ClearSearchHistoryUseCase: Sendable {
    func callAsFunction() async
}

public struct DefaultClearSearchHistoryUseCase: ClearSearchHistoryUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func callAsFunction() async {
        await searchHistoryRepository.clearRecentSearches()
    }
}
