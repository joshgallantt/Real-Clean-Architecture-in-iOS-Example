import Combine

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their bag. Those three hold for every protocol below, so they are
// cited once; a comment on any one of them says only what is true of that one.

/// The one way a shopper changes what their bag holds: this product, this many, at this price.
/// The first of something puts it in, a different count changes it, and none takes it out. It
/// takes a whole line because the line may not exist yet, and a caller that has one already says
/// what it should become with `withQuantity`.
///
/// It is also how a bag is kept as its shopper last saw it: each line a check changed is set to
/// what the check made of it, so there is no second way to write a bag.
public protocol SetBagItemUseCase: Sendable {
    @MainActor
    func callAsFunction(_ item: BagItem)
}

/// Asks the shop about everything in the bag and answers with the bag as it truthfully is now, what
/// changed since it was kept, and what the shop said — in one reply, so a screen need not ask
/// twice. It keeps nothing: the bag that is stored is still the one the shopper last saw, which is
/// what makes the changes something to work out again rather than something to remember.
///
/// A shop that could not be reached has said nothing, and nothing is concluded from nothing: the
/// answer is then the bag as it was kept, with nothing asked and nothing changed.
///
/// It asks the shop itself rather than being handed the answer. `PlaceOrderUseCase` reaches for
/// `GetSessionUseCase` the same way: a use case may compose another component's use cases, and
/// asking is part of checking rather than something a screen does on its behalf.
public protocol CheckBagUseCase: Sendable {
    func callAsFunction() async -> CheckedBag
}

/// The bag as it was kept — which is the bag as its shopper last saw it.
public protocol ObserveBagUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Bag, Never>
}
