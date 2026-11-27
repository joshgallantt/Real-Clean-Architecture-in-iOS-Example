import Tracking

/// Fowler, *PoEAA* (2002) — Gateway: one place events are sent — GA4, Firebase, mParticle. A
/// data-layer contract: the tracking repository hands every event to each, and each maps what the
/// event says about itself into one vendor's shape. A new destination is a new conformance and a
/// line in the composition root; a new event is a case in `EventName` and a line in each vendor's
/// vocabulary, and nothing here.
///
/// No feature is handed one. Screens report to use cases; which destinations hear about it is
/// decided in the composition root, and nowhere else.
@MainActor
public protocol TrackingDestination: AnyObject, Sendable {
    func send(_ event: TrackingEvent)

    /// Send anything held back for batching.
    func flush()
}
