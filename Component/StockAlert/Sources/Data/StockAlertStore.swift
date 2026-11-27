import Session
import StockAlert

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving. Today a file on the device; the day a shopper is to
/// be told on more than one, a request — and nothing inward changes.
public protocol StockAlertStore: Sendable {
    func getItems(for owner: UserID?) -> [StockAlert]

    /// Throws when the list could not be kept. What went wrong is the store's business; that it
    /// did not happen is the domain's.
    func setItems(_ items: [StockAlert], for owner: UserID?) async throws
}
