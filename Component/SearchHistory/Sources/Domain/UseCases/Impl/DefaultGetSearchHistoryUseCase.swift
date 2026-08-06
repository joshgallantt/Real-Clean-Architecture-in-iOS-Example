public struct DefaultGetSearchHistoryUseCase: GetSearchHistoryUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> SearchHistory {
        repository.history()
    }
}
