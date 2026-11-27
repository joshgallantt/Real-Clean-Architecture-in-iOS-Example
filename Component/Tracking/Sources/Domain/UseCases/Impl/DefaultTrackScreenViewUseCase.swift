public struct DefaultTrackScreenViewUseCase: TrackScreenViewUseCase {
    private let trackEvent: TrackEventUseCase

    public init(trackEvent: TrackEventUseCase) {
        self.trackEvent = trackEvent
    }

    @MainActor
    public func callAsFunction(_ screen: String) {
        trackEvent(.screenViewed(screen))
    }
}
