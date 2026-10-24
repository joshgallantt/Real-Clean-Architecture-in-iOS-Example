/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol UserStore: Sendable {
    func find(email: String) -> StoredUser?
    func save(_ user: StoredUser)
}
