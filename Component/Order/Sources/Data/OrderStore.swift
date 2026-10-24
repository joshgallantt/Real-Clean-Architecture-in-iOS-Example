import Order
import Session

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving. Today a file on the device; the day orders come back
/// from a server, a request — and nothing inward changes.
public protocol OrderStore: Sendable {
    func getOrders(for owner: UserID?) -> Orders
    func setOrders(_ orders: Orders, for owner: UserID?) async
}
