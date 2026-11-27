/// Evans, *Domain-Driven Design* (2003), Ch. 10 — Assertions: the rules every event shares, whoever
/// reported it.
///
/// - Every event says which screen it happened on. One with no screen name is not reported — and
///   says so in a debug build, so a view with no `.trackingScreen` above it fails loudly rather
///   than quietly reporting from nowhere.
/// - A position before the start of a list is not a position, so it is not reported rather than
///   reported wrong.
public struct DefaultTrackEventUseCase: TrackEventUseCase {
    private let repository: TrackingRepository

    public init(repository: TrackingRepository) {
        self.repository = repository
    }

    @MainActor
    public func callAsFunction(_ event: TrackingEvent) {
        guard isReportable(event.context) else { return }
        repository.record(event)
    }

    private func isReportable(_ context: TrackingContext) -> Bool {
        guard !context.screen.isEmpty else {
            assertionFailure("Reported from a view with no .trackingScreen above it")
            return false
        }
        if let position = context.listPosition { return position.index >= 0 }
        return true
    }
}
