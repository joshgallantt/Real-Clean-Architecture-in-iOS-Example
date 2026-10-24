import Combine
import Product

// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// Everything a shopper can ask of their waitlist. Those three hold for every protocol below, so
// they are cited once; a comment on any one of them says only what is true of that one.

public protocol ObserveProductIsWaitlistedUseCase: Sendable {
    @MainActor
    func callAsFunction(productId: ProductID) -> AnyPublisher<Bool, Never>
}

/// The whole waitlist, for whoever needs to know that it changed. The two product lists below
/// depend on the shop as well, so they cannot be publishers of stored state — this is the signal
/// that they are worth asking for again.
public protocol ObserveWaitlistUseCase: Sendable {
    @MainActor
    func callAsFunction() -> AnyPublisher<Waitlist, Never>
}

/// One bell, with a state — the setter for what `ObserveProductIsWaitlistedUseCase` reports. A
/// caller says what it wants to be true and the domain works out what that takes, so the button
/// that draws the bell never has to pick between joining and leaving from its own state.
public protocol SetProductIsWaitlistedUseCase: Sendable {
    @discardableResult
    func callAsFunction(productId: ProductID, isWaitlisted: Bool) async -> Result<Void, WaitlistError>
}

/// Evans, Ch. 9 — Making Implicit Concepts Explicit: what the shopper is still waiting for. Not the
/// whole waitlist — that includes things that have already come back — but the products the shop
/// still has none of.
public protocol GetStillSoldOutProductsUseCase: Sendable {
    func callAsFunction() async -> Result<[Product], WaitlistError>
}

/// Evans, Ch. 9 — Making Implicit Concepts Explicit: the other half, and the one the bell was
/// tapped for.
///
/// A product stays on the waitlist when it comes back. Being on the list is wanting to be told, and
/// whether the shop has any is a fact about the shop, not about the shopper — so nothing is taken
/// off on their behalf, and something that sells out again simply moves back. Only
/// `SetProductIsWaitlistedUseCase(isWaitlisted: false)` takes something off.
public protocol GetBackInStockProductsUseCase: Sendable {
    func callAsFunction() async -> Result<[Product], WaitlistError>
}
