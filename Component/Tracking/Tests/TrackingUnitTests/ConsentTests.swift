import Testing
import Tracking
import TrackingData
import TrackingTestSupport

@MainActor
@Suite("Nothing is sent that the person has not agreed to")
struct ConsentTests {
    private let firebase = SpyFirebaseClient()
    private let mParticle = SpyMParticleClient()
    private let logger = SpyLoggerClient()
    private let screen = TrackingEvent(name: .screenViewed, context: .screen("home"), items: [], properties: [:])
    private let tap = TrackingEvent(name: .elementSelected, context: .screen("home"), items: [], properties: ["element": "retry"])

    private func repository(_ status: TrackingConsentStatus, answer: TrackingConsentStatus) -> DefaultTrackingRepository {
        DefaultTrackingRepository(
            firebase: firebase,
            mParticle: mParticle,
            logger: logger,
            consent: StubTrackingConsentSource(status: status, answer: answer)
        )
    }

    @Test("Once they have agreed, every event goes through")
    func granted() {
        repository(.granted, answer: .granted).record(screen)

        #expect(logger.lines == ["Screen Viewed | screen=home"])
    }

    @Test("Once they have declined, nothing does")
    func denied() {
        let repository = repository(.denied, answer: .denied)

        repository.record(screen)

        #expect(logger.lines.isEmpty)
    }

    @Test("Before they are asked, events wait — and are sent, in order, if they agree")
    func waitThenAgree() async {
        let repository = repository(.notDetermined, answer: .granted)

        repository.record(screen)
        repository.record(tap)
        #expect(logger.lines.isEmpty)

        _ = await repository.requestConsent()

        #expect(logger.lines == ["Screen Viewed | screen=home", "Element Selected | screen=home | element=retry"])
    }

    @Test("Events that waited are forgotten if they decline")
    func waitThenDecline() async {
        let repository = repository(.notDetermined, answer: .denied)

        repository.record(screen)
        _ = await repository.requestConsent()
        repository.record(tap)

        #expect(logger.lines.isEmpty)
    }

    @Test("A prompt nobody answers does not hold on to everything forever")
    func waitingIsCapped() async {
        let repository = repository(.notDetermined, answer: .granted)

        for _ in 0..<(DefaultTrackingRepository.maxWaiting + 10) { repository.record(screen) }
        _ = await repository.requestConsent()

        #expect(logger.lines.count == DefaultTrackingRepository.maxWaiting)
    }

    @Test("Asking again once they have answered sends nothing twice")
    func askingTwice() async {
        let repository = repository(.notDetermined, answer: .granted)

        repository.record(screen)
        _ = await repository.requestConsent()
        _ = await repository.requestConsent()

        #expect(logger.lines.count == 1)
    }

    @Test("Every client hears every event, each in its own shape")
    func everyClient() {
        repository(.granted, answer: .granted).record(screen)

        #expect(firebase.events.map(\.name) == ["screen_view"])
        #expect(mParticle.events.map(\.kind) == [.screenView])
        #expect(logger.lines == ["Screen Viewed | screen=home"])
    }
}
