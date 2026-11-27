import Tracking

/// Records each screen view as the event it would become. It applies none of the use case's rules.
@MainActor
public final class SpyTrackScreenViewUseCase: TrackScreenViewUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ screen: String) {
        events.append(.screenViewed(screen))
    }
}
