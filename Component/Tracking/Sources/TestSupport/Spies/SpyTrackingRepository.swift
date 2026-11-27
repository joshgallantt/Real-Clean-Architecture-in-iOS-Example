import Tracking

@MainActor
public final class SpyTrackingRepository: TrackingRepository {
    public init() {}

    public private(set) var events: [TrackingEvent] = []
    public private(set) var flushCount = 0
    public private(set) var timesAskedForConsent = 0

    public func record(_ event: TrackingEvent) {
        events.append(event)
    }

    public func flush() {
        flushCount += 1
    }

    public func requestConsent() async -> TrackingConsentStatus {
        timesAskedForConsent += 1
        return .granted
    }
}
