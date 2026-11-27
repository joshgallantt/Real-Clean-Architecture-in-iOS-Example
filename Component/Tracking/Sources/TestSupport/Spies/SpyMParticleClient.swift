import Synchronization
import TrackingData

public final class SpyMParticleClient: MParticleClient {
    private let logged = Mutex<[MParticleEventDTO]>([])

    public init() {}

    public var events: [MParticleEventDTO] {
        logged.withLock { $0 }
    }

    public func logEvent(_ event: MParticleEventDTO) {
        logged.withLock { $0.append(event) }
    }
}
