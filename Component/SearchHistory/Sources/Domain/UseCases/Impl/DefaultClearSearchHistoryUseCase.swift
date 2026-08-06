public struct DefaultClearSearchHistoryUseCase: ClearSearchHistoryUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() {
        repository.save(repository.history().cleared())
    }
}
