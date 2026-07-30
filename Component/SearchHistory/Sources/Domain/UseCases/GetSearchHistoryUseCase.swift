public protocol GetSearchHistoryUseCase: Sendable {
    func callAsFunction() async -> SearchHistory
}

public struct DefaultGetSearchHistoryUseCase: GetSearchHistoryUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    public func callAsFunction() async -> SearchHistory {
        await repository.history()
    }
}
