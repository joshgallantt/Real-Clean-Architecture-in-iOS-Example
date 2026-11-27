import Synchronization
import TrackingData

/// The log a test reads back: exactly what the unified log would have been handed, as text.
public final class SpyLoggerClient: LoggerClient {
    private let written = Mutex<[String]>([])

    public init() {}

    public var lines: [String] {
        written.withLock { $0 }
    }

    public func log(_ line: String) {
        written.withLock { $0.append(line) }
    }
}
