import Tracking

/// Fowler, *PoEAA* (2002) — Gateway: whoever knows what the person said about being tracked, and
/// can ask them. The system's App Tracking Transparency prompt in the app; a stub in a test.
@MainActor
public protocol TrackingConsentSource: AnyObject, Sendable {
    var status: TrackingConsentStatus { get }

    /// Asks, if nobody has yet, and answers with what they said.
    func request() async -> TrackingConsentStatus
}
