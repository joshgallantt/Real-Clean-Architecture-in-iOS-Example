import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002) — Service
/// Layer.
///
/// Evans, *Domain-Driven Design* (2003) — Intention-Revealing Interfaces.
public protocol RecordSearchUseCase: Sendable {
    /// Evans, *Domain-Driven Design* (2003) — Value Objects: takes a `SearchTerm`, so there is no
    /// blank-or-not decision left for a caller to make differently.
    @MainActor
    func callAsFunction(_ term: SearchTerm)
}

public struct DefaultRecordSearchUseCase: RecordSearchUseCase {
    private let repository: SearchHistoryRepository

    public init(repository: SearchHistoryRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ term: SearchTerm) {
        repository.save(repository.history().recording(term))
    }
}
