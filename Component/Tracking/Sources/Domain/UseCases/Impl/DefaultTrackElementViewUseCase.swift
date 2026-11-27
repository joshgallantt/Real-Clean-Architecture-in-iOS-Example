/// Every time something comes into view it is reported, including a card scrolled away from and
/// back to. Tracking says what happened; how many of those count as one is a question for whoever
/// reads the report, who can always count fewer but can never count what was not sent.
public struct DefaultTrackElementViewUseCase: TrackElementViewUseCase {
    private let trackEvent: TrackEventUseCase

    public init(trackEvent: TrackEventUseCase) {
        self.trackEvent = trackEvent
    }

    @MainActor
    public func callAsFunction(_ element: String, in context: TrackingContext) {
        trackEvent(TrackingEvent(name: .elementViewed, context: context, items: [], properties: ["element": element]))
    }

    @MainActor
    public func callAsFunction(_ element: String, about item: TrackedItem, in context: TrackingContext) {
        trackEvent(TrackingEvent(name: .elementViewed, context: context, items: [item], properties: ["element": element]))
    }
}
