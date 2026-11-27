/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: the domain says it
/// needs somewhere to put an event and someone to ask about consent; the data layer decides whether
/// an event may be sent yet, and each client's mapper decides in what shape.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Separated Interface.
///
/// Recording is not `async` and does not throw. Measuring a tap must never be a reason a tap is
/// slow, and a shopper must never be told that the app failed to watch them.
@MainActor
public protocol TrackingRepository: Sendable {
    func record(_ event: TrackingEvent)

    /// Asks the person, if nobody has yet, whether they may be tracked.
    func requestConsent() async -> TrackingConsentStatus
}
