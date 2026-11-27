import Tracking
import TrackingData

@MainActor
public final class SpyTrackingDestination: TrackingDestination {
    public init() {}

    public private(set) var events: [TrackingEvent] = []
    public private(set) var flushCount = 0

    public func send(_ event: TrackingEvent) {
        events.append(event)
    }

    public func flush() {
        flushCount += 1
    }
}
