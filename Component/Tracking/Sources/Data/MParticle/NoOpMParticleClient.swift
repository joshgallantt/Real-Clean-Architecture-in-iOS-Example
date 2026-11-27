/// Sends nothing. The SDK is not linked, so this is where an `MPEvent` or `MPCommerceEvent` would
/// be built from the DTO and logged — linking it is a change to this file and nothing else.
public struct NoOpMParticleClient: MParticleClient {
    public init() {}

    public func logEvent(_ event: MParticleEventDTO) {}
}
