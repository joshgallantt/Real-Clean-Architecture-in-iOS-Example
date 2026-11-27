import Testing
import Tracking
import TrackingData
import TrackingTestSupport

@MainActor
@Suite("Nothing is sent that the person has not agreed to")
struct ConsentTests {
    private let destination = SpyTrackingDestination()
    private let screen = TrackingEvent.screenViewed("home")
    private let tap = TrackingEvent.tapped("retry", in: .screen("home"))

    private func repository(_ status: TrackingConsentStatus, answer: TrackingConsentStatus) -> DefaultTrackingRepository {
        DefaultTrackingRepository(destinations: [destination], consent: StubTrackingConsentSource(status: status, answer: answer))
    }

    @Test("Once they have agreed, every event goes through")
    func granted() {
        repository(.granted, answer: .granted).record(screen)

        #expect(destination.events == [screen])
    }

    @Test("Once they have declined, nothing does")
    func denied() {
        let repository = repository(.denied, answer: .denied)

        repository.record(screen)
        repository.flush()

        #expect(destination.events.isEmpty)
        #expect(destination.flushCount == 0)
    }

    @Test("Before they are asked, events wait — and are sent, in order, if they agree")
    func waitThenAgree() async {
        let repository = repository(.notDetermined, answer: .granted)

        repository.record(screen)
        repository.record(tap)
        #expect(destination.events.isEmpty)

        _ = await repository.requestConsent()

        #expect(destination.events == [screen, tap])
    }

    @Test("Events that waited are forgotten if they decline")
    func waitThenDecline() async {
        let repository = repository(.notDetermined, answer: .denied)

        repository.record(screen)
        _ = await repository.requestConsent()
        repository.record(tap)

        #expect(destination.events.isEmpty)
    }

    @Test("A prompt nobody answers does not hold on to everything forever")
    func waitingIsCapped() async {
        let repository = repository(.notDetermined, answer: .granted)

        for _ in 0..<(DefaultTrackingRepository.maxWaiting + 10) { repository.record(screen) }
        _ = await repository.requestConsent()

        #expect(destination.events.count == DefaultTrackingRepository.maxWaiting)
    }

    @Test("Asking again once they have answered sends nothing twice")
    func askingTwice() async {
        let repository = repository(.notDetermined, answer: .granted)

        repository.record(screen)
        _ = await repository.requestConsent()
        _ = await repository.requestConsent()

        #expect(destination.events.count == 1)
    }

    @Test("Every destination hears every event")
    func everyDestination() {
        let second = SpyTrackingDestination()
        let repository = DefaultTrackingRepository(
            destinations: [destination, second],
            consent: StubTrackingConsentSource(status: .granted, answer: .granted)
        )

        repository.record(screen)
        repository.flush()

        #expect(destination.events == second.events)
        #expect(second.flushCount == 1)
    }
}
