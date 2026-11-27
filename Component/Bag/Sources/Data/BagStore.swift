import Bag
import Session

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol BagStore: Sendable {
    func getBag(for session: Session) -> Bag
    func setBag(_ bag: Bag, for session: Session) async
}
