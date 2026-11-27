import Tracking

/// Records each tap as the event it would become.
@MainActor
public final class SpyTrackElementInteractionUseCase: TrackElementInteractionUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ element: String, in context: TrackingContext) {
        events.append(.tapped(element, in: context))
    }

    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        events.append(.tapped(element, about: item, in: context))
    }
}
