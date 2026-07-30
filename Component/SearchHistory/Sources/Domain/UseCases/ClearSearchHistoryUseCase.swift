public protocol ClearSearchHistoryUseCase: Sendable {
    func callAsFunction() async
}

public struct DefaultClearSearchHistoryUseCase: ClearSearchHistoryUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    public func callAsFunction() async {
        await repository.save(await repository.history().cleared())
    }
}
