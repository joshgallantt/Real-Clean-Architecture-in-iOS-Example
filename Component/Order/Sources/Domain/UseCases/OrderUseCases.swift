import Combine

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask about buying and what they have bought. Those three hold for both
// protocols below, so they are cited once; a comment on either says only what is true of that one.

public protocol ObserveOrdersUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Orders, Never>
}

/// Checking out is not a module, it is this. What a shopper is checking out — one product from its
/// page, or everything in their bag — is decided by whoever calls it, and the rule is the same
/// either way.
public protocol PlaceOrderUseCase: Sendable {
    @MainActor
    func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError>
}
