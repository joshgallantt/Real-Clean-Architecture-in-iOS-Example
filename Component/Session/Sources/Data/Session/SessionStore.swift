import Combine
import Session

@MainActor
/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SessionStore: AnyObject, Sendable {
    var session: Session { get }
    var sessionPublisher: AnyPublisher<Session, Never> { get }
    var authToken: AuthToken? { get }
    func setUser(_ user: User, token: AuthToken)
    func clear()
}
