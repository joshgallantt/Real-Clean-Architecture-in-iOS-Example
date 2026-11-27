import Tracking

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories: it maps every event into each
/// client's shape and hands it over, and decides nothing about what the event means.
///
/// It sends nothing the person has not agreed to, so no use case, view model or client has to
/// know consent exists.
///
/// - Agreed: every event goes to every client.
/// - Not asked yet: events wait, so the screens a person saw before the prompt are not lost if they
///   agree. Only so many wait — a prompt nobody answers must not become a memory leak.
/// - Declined: everything waiting is forgotten, and so is everything after.
@MainActor
public final class DefaultTrackingRepository: TrackingRepository {
    public static let maxWaiting = 500

    private let firebase: FirebaseClient
    private let mParticle: MParticleClient
    private let logger: LoggerClient
    private let consent: TrackingConsentSource
    private var waiting: [TrackingEvent] = []

    public init(firebase: FirebaseClient, mParticle: MParticleClient, logger: LoggerClient, consent: TrackingConsentSource) {
        self.firebase = firebase
        self.mParticle = mParticle
        self.logger = logger
        self.consent = consent
    }

    public func record(_ event: TrackingEvent) {
        switch consent.status {
        case .granted:
            send(event)
        case .notDetermined:
            guard waiting.count < Self.maxWaiting else { return }
            waiting.append(event)
        case .denied:
            waiting = []
        }
    }

    public func requestConsent() async -> TrackingConsentStatus {
        let held = waiting
        waiting = []
        let answer = await consent.request()
        switch answer {
        case .granted:
            held.forEach(send)
        case .notDetermined:
            waiting = held + waiting
        case .denied:
            break
        }
        return answer
    }

    private func send(_ event: TrackingEvent) {
        firebase.logEvent(FirebaseEventMapper().map(event))
        mParticle.logEvent(MParticleEventMapper().map(event))
        logger.log(LoggerEventMapper().map(event))
    }
}
