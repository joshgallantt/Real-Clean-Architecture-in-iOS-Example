public protocol GetSearchHistoryUseCase: Sendable {
    func execute() async -> [String]
}

public struct DefaultGetSearchHistoryUseCase: GetSearchHistoryUseCase {
    let searchHistoryRepository: SearchHistoryRepository

    public init(searchHistoryRepository: SearchHistoryRepository) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    public func execute() async -> [String] {
        await searchHistoryRepository.getRecentSearches()
    }
}
