import Tracking

/// What a view model reported, so its test can say exactly which event it built. It applies none
/// of the shared rules.
@MainActor
public final class SpyTrackEventUseCase: TrackEventUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ event: TrackingEvent) {
        events.append(event)
    }
}
