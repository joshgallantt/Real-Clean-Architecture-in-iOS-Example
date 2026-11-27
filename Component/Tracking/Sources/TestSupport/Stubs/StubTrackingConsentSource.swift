import Tracking
import TrackingData

/// An answer decided by the test: what the person has said so far, and what they will say if asked.
@MainActor
public final class StubTrackingConsentSource: TrackingConsentSource {
    public var status: TrackingConsentStatus
    public var answer: TrackingConsentStatus
    public private(set) var timesAsked = 0

    public init(status: TrackingConsentStatus, answer: TrackingConsentStatus) {
        self.status = status
        self.answer = answer
    }

    public func request() async -> TrackingConsentStatus {
        timesAsked += 1
        status = answer
        return answer
    }
}
