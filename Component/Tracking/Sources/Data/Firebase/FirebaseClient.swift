/// The edge of the Firebase Analytics SDK: one call, `Analytics.logEvent(_:parameters:)`. The
/// repository hands it an event already in Firebase's shape and knows nothing else about the SDK.
public protocol FirebaseClient: Sendable {
    func logEvent(_ event: FirebaseEventDTO)
}
