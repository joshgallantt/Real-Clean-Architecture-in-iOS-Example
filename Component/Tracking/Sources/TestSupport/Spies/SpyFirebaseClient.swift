import Synchronization
import TrackingData

public final class SpyFirebaseClient: FirebaseClient {
    private let logged = Mutex<[FirebaseEventDTO]>([])

    public init() {}

    public var events: [FirebaseEventDTO] {
        logged.withLock { $0 }
    }

    public func logEvent(_ event: FirebaseEventDTO) {
        logged.withLock { $0.append(event) }
    }
}
