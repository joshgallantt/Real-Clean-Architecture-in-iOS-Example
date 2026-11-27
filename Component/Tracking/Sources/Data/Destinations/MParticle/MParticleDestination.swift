import Tracking

/// mParticle, by its Events API. It sends nothing — each event it would upload is written to its
/// log instead, so linking the SDK is a change to this file and nothing else.
@MainActor
public final class MParticleDestination: TrackingDestination {
    private let log: TrackingLog
    private let mapper = MParticleEventMapper()

    public init(log: TrackingLog) {
        self.log = log
    }

    public func send(_ event: TrackingEvent) {
        log.write(mapper.payload(for: event).line)
    }

    /// Nothing is held: mParticle's SDK uploads on its own schedule.
    public func flush() {}
}
