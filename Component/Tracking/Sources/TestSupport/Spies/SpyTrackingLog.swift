import Synchronization
import TrackingData

/// The log a test reads back: exactly what the unified log would have been handed, as text.
public final class SpyTrackingLog: TrackingLog {
    private let written = Mutex<[String]>([])

    public init() {}

    public var entries: [String] {
        written.withLock { $0 }
    }

    public func write(_ entry: String) {
        written.withLock { $0.append(entry) }
    }
}
