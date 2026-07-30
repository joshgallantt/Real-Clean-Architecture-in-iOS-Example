/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
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
