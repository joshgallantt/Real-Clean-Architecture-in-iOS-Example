import Combine
import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their bag. Those three hold for every protocol below, so they are
// cited once; a comment on any one of them says only what is true of that one.

/// A shopper says they have seen what happened to one product, so every notice about that product
/// goes.
public protocol AcknowledgeNoticesUseCase: Sendable {
    @MainActor
    func callAsFunction(aboutProductId productId: ProductID)
}

public protocol AddItemToBagUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

/// It asks the shop itself rather than being handed the answer. `PlaceOrderUseCase` reaches for
/// `GetSessionUseCase` the same way: a use case may compose another component's use cases, and
/// asking is part of catching up rather than something a screen does on its behalf.
public protocol BringBagUpToDateUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction() async -> [Product]
}

public protocol ObserveBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Int, Never>
}

public protocol ObserveBagUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Bag, Never>
}

public protocol ObserveNoticesUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Notices, Never>
}

public protocol SetBagItemQuantityUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID, to quantity: Int)
}
