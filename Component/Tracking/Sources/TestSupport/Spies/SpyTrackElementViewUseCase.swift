import Tracking

/// Records each view as the event it would become, so a view model test says exactly which element,
/// about which item, where, in one `==`. It applies none of the shared rules.
@MainActor
public final class SpyTrackElementViewUseCase: TrackElementViewUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ element: String, in context: TrackingContext) {
        events.append(TrackingEvent(name: .elementViewed, context: context, items: [], properties: ["element": element]))
    }

    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        events.append(TrackingEvent(name: .elementViewed, context: context, items: [item], properties: ["element": element]))
    }
}
