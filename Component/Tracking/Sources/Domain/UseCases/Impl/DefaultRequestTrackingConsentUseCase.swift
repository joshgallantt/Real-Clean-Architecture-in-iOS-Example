public struct DefaultRequestTrackingConsentUseCase: RequestTrackingConsentUseCase {
    private let repository: TrackingRepository

    public init(repository: TrackingRepository) {
        self.repository = repository
    }

    @MainActor
    @discardableResult
    public func callAsFunction() async -> TrackingConsentStatus {
        await repository.requestConsent()
    }
}
