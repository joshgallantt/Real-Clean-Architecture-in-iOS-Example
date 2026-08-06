import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol ObserveOrdersUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Orders, Never>
}

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces: checking out is
/// not a module, it is this. What a shopper is checking out — one product from its page, or
/// everything in their bag — is decided by whoever calls it, and the rule is the same either way.
public protocol PlaceOrderUseCase: Sendable {
    @MainActor
    func callAsFunction(_ lines: [OrderLine]) async -> Result<Order, OrderError>
}
