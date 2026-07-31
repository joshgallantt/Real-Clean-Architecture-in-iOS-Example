import Combine

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
/// Service Layer.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
public protocol ObserveOrdersUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Orders, Never>
}

public struct DefaultObserveOrdersUseCase: ObserveOrdersUseCase {
    private let repository: OrderRepository

    public init(repository: OrderRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<Orders, Never> {
        repository.ordersPublisher
    }
}
