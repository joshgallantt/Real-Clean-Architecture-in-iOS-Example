/// Every tap counts: tapping the same card twice is two decisions.
public struct DefaultTrackElementInteractionUseCase: TrackElementInteractionUseCase {
    private let trackEvent: TrackEventUseCase

    public init(trackEvent: TrackEventUseCase) {
        self.trackEvent = trackEvent
    }

    @MainActor
    public func callAsFunction(_ element: String, in context: TrackingContext) {
        trackEvent(.tapped(element, in: context))
    }

    @MainActor
    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        trackEvent(.tapped(element, about: item, in: context))
    }
}
