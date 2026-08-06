/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol GetSearchHistoryUseCase: Sendable {
    @MainActor
    func callAsFunction() -> SearchHistory
}

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
