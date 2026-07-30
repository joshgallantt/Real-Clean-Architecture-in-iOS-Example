/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
public protocol SearchHistoryRepository: Sendable {
    func history() async -> SearchHistory
    func save(_ history: SearchHistory) async
}
