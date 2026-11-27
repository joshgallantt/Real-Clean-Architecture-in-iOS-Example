import Tracking

/// Records each view as the event it would become, so a view model test says exactly which element,
/// about which item, where, in one `==`. It applies none of the shared rules.
@MainActor
public final class SpyTrackElementViewUseCase: TrackElementViewUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ element: String, in context: TrackingContext) {
        events.append(.viewed(element, in: context))
    }

    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        events.append(.viewed(element, about: item, in: context))
    }
}
