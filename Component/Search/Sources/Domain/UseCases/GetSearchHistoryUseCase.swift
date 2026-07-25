public protocol GetSearchHistoryUseCase: Sendable {
    func callAsFunction() async -> [String]
}

public struct DefaultGetSearchHistoryUseCase: GetSearchHistoryUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func callAsFunction() async -> [String] {
        await searchHistoryRepository.getRecentSearches()
    }
}
