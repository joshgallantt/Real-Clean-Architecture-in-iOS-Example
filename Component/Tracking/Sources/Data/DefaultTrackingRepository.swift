import Tracking

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories: it hands every event to every
/// destination and decides nothing about what the event means.
///
/// It sends nothing the person has not agreed to, so no use case, view model or destination has to
/// know consent exists.
///
/// - Agreed: every event goes to every destination.
/// - Not asked yet: events wait, so the screens a person saw before the prompt are not lost if they
///   agree. Only so many wait — a prompt nobody answers must not become a memory leak.
/// - Declined: everything waiting is forgotten, and so is everything after.
@MainActor
public final class DefaultTrackingRepository: TrackingRepository {
    public static let maxWaiting = 500

    private let destinations: [TrackingDestination]
    private let consent: TrackingConsentSource
    private var waiting: [TrackingEvent] = []

    public init(destinations: [TrackingDestination], consent: TrackingConsentSource) {
        self.destinations = destinations
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

    public func flush() {
        guard consent.status == .granted else { return }
        destinations.forEach { $0.flush() }
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
        destinations.forEach { $0.send(event) }
    }
}
