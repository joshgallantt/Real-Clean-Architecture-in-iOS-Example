import Combine
import Product

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

public struct DefaultObserveWaitlistStatusUseCase: ObserveWaitlistStatusUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never> {
        repository.alertsPublisher
            .map { $0.waitingFor(productId: productId) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

public struct DefaultObserveWaitlistUseCase: ObserveWaitlistUseCase {
    private let repository: StockAlertRepository

    public init(repository: StockAlertRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() -> AnyPublisher<StockAlerts, Never> {
        repository.alertsPublisher
    }
}
