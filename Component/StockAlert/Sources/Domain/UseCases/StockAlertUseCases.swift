import Combine
import Product

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: what the
/// shopper is still waiting for. Not the asks — the asks include things that have already arrived —
/// but the ones the shop still has none of.
public protocol GetWaitlistProductsUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: the other half,
/// and the one the bell was tapped for.
///
/// A product stays on the waitlist when it comes back. The ask is a record of wanting to be told,
/// and whether the shop has any is a fact about the shop, not about the ask — so nothing is removed
/// on the shopper's behalf and something that sells out again simply moves back. Only
/// `SetStockAlertForProductUseCase(isOn: false)` takes something off.
public protocol GetBackInStockProductsUseCase: Sendable {
    @MainActor
    func callAsFunction() async -> Result<[Product], StockAlertError>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces: whether this one
/// product is on the shopper's waitlist. It is what a bell on a card is, and nothing more — a tile
/// has no interest in the rest of what somebody is waiting for.
public protocol ObserveWaitlistStatusUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: the whole waitlist, for whoever
/// needs to know that it changed. `GetWaitlistProductsUseCase` answers what is *on* it, which
/// depends on the shop as well and so cannot be a publisher of stored state — this is the signal
/// that it is worth asking again.
public protocol ObserveWaitlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<StockAlerts, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces: one bell, with a
/// state. It was two use cases, asking and stopping, which is two ways of writing one toggle — and
/// every caller had to hold both and pick, so the button that renders it had to know which of the
/// two its own current state implied.
public protocol SetStockAlertForProductUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction(productId: ProductID, isOn: Bool) async -> Result<Void, StockAlertError>
}
