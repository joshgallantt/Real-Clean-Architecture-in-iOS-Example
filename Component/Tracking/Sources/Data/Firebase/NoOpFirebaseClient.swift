/// Sends nothing. The SDK is not linked, so this is where `Analytics.logEvent(event.name,
/// parameters:)` would go — linking it is a change to this file and nothing else.
public struct NoOpFirebaseClient: FirebaseClient {
    public init() {}

    public func logEvent(_ event: FirebaseEventDTO) {}
}
