public struct DefaultSendHeldTrackingUseCase: SendHeldTrackingUseCase {
    private let repository: TrackingRepository

    public init(repository: TrackingRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction() {
        repository.flush()
    }
}
