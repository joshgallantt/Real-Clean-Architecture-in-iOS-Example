/// The edge of the mParticle SDK: one call, `MParticle.sharedInstance().logEvent(_:)`. The
/// repository hands it an event already in mParticle's shape and knows nothing else about the SDK.
public protocol MParticleClient: Sendable {
    func logEvent(_ event: MParticleEventDTO)
}
