import Tracking

@MainActor
public final class SpyRequestTrackingConsentUseCase: RequestTrackingConsentUseCase {
    public init() {}

    public private(set) var timesAsked = 0

    @discardableResult
    public func callAsFunction() async -> TrackingConsentStatus {
        timesAsked += 1
        return .granted
    }
}
