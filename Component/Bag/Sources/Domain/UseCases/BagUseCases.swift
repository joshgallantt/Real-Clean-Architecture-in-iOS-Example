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

/// The one way a shopper changes what their bag holds: this product, this many, at this price.
/// The first of something puts it in, a different count changes it, and none takes it out. It
/// takes a whole line because the line may not exist yet, and a caller that has one already says
/// what it should become with `withQuantity`.
public protocol SetBagItemUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

/// Checks the bag against the shop as it is now: each line takes today's price, is cut to what is
/// left in stock, or goes if the shop has none, and a notice is left for whatever changed. Returns
/// the products it was told about, so the screen need not ask twice.
///
/// It asks the shop itself rather than being handed the answer. `PlaceOrderUseCase` reaches for
/// `GetSessionUseCase` the same way: a use case may compose another component's use cases, and
/// asking is part of catching up rather than something a screen does on its behalf.
public protocol RefreshBagUseCase: Sendable {
    @discardableResult
    func callAsFunction() async -> [Product]
}


public protocol ObserveBagUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Bag, Never>
}

public protocol ObserveNoticesUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Notices, Never>
}

