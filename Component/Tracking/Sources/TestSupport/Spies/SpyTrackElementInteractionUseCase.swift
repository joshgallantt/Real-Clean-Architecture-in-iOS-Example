import Tracking

/// Records each tap as the event it would become.
@MainActor
public final class SpyTrackElementInteractionUseCase: TrackElementInteractionUseCase {
    public init() {}

    public private(set) var events: [TrackingEvent] = []

    public func callAsFunction(_ element: String, in context: TrackingContext) {
        events.append(TrackingEvent(name: .elementSelected, context: context, items: [], properties: ["element": element]))
    }

    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        events.append(TrackingEvent(name: .elementSelected, context: context, items: [item], properties: ["element": element]))
    }
}
