import Session

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SearchHistoryStore: Sendable {
    func getQueries(for session: Session) -> [String]
    func setQueries(_ queries: [String], for session: Session)
}
