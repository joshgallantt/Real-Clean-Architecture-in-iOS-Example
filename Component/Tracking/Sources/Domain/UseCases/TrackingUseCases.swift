// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules. Fowler, *PoEAA* (2002), Ch. 9 —
// Service Layer. Evans, *Domain-Driven Design* (2003), Ch. 10 — Intention-Revealing Interfaces.
//
// What a screen can report: that it was viewed, that something on it was seen or touched, and —
// through `TrackEventUseCase` — a step through the shop, such as adding to a bag or placing an
// order.
//
// `@MainActor`, because a tap happens there and so does every view model that reports one.

/// A screen came into view. A screen and an element are each just a name, so each is a `String`;
/// which is which is said by the use case that is called.
public protocol TrackScreenViewUseCase: Sendable {
    @MainActor
    func callAsFunction(_ screen: String)
}

/// Something was seen. Two calls rather than one with an optional item: a snackbar about nothing
/// and a card about a product each say which they are by which they call.
public protocol TrackElementViewUseCase: Sendable {
    @MainActor
    func callAsFunction(_ element: String, in context: TrackingContext)

    @MainActor
    func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext)
}

/// A shopper touched something.
public protocol TrackElementInteractionUseCase: Sendable {
    @MainActor
    func callAsFunction(_ element: String, in context: TrackingContext)

    @MainActor
    func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext)
}

/// A step through the shop. What a view model calls to report one: it builds the event, with a
/// name from `EventName`, out of what it has just done, and hands it on here. The one door every
/// event goes through, so the rules they all share are applied in one place.
public protocol TrackEventUseCase: Sendable {
    @MainActor
    func callAsFunction(_ event: TrackingEvent)
}

/// Asks the person whether they may be tracked, if nobody has asked them yet.
public protocol RequestTrackingConsentUseCase: Sendable {
    @MainActor
    @discardableResult
    func callAsFunction() async -> TrackingConsentStatus
}

/// Sends anything held back for batching, before the app is suspended.
public protocol SendHeldTrackingUseCase: Sendable {
    @MainActor
    func callAsFunction()
}
