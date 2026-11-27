import Tracking
import TrackingData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. The
/// composition root chooses the destinations and the consent source; everything else receives use
/// cases. Not unit tested — there is no behaviour here to test.
@MainActor
public struct TrackingDI {
    public let trackScreenViewUseCase: TrackScreenViewUseCase
    public let trackElementViewUseCase: TrackElementViewUseCase
    public let trackElementInteractionUseCase: TrackElementInteractionUseCase

    /// What a view model reports a step through the shop with.
    public let trackEventUseCase: TrackEventUseCase

    public let requestTrackingConsentUseCase: RequestTrackingConsentUseCase
    public let sendHeldTrackingUseCase: SendHeldTrackingUseCase

    public init(destinations: [TrackingDestination], consent: TrackingConsentSource) {
        let repository = DefaultTrackingRepository(destinations: destinations, consent: consent)
        let trackEvent = DefaultTrackEventUseCase(repository: repository)

        self.trackEventUseCase = trackEvent
        self.trackScreenViewUseCase = DefaultTrackScreenViewUseCase(trackEvent: trackEvent)
        self.trackElementViewUseCase = DefaultTrackElementViewUseCase(trackEvent: trackEvent)
        self.trackElementInteractionUseCase = DefaultTrackElementInteractionUseCase(trackEvent: trackEvent)
        self.requestTrackingConsentUseCase = DefaultRequestTrackingConsentUseCase(repository: repository)
        self.sendHeldTrackingUseCase = DefaultSendHeldTrackingUseCase(repository: repository)
    }
}
