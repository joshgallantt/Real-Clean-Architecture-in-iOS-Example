import Combine
import Foundation
import Testing
import Session
@testable import Settings

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the composition itself, in the language of
/// the system. Which settings a shopper is offered is `OfferedSettingsTests`' subject; this says
/// that the answer is republished whenever either half of it moves.
@MainActor
@Suite("Observing the settings a shopper is offered")
struct ObserveOfferedSettingsUseCaseTests {
    private func makeUseCase(
        settings: StubObserveSettings,
        session: StubObserveSession
    ) -> DefaultObserveOfferedSettingsUseCase {
        DefaultObserveOfferedSettingsUseCase(observeSettings: settings, observeSession: session)
    }

    @Test("A guest is published the settings they are offered, with the values they hold")
    func aGuestIsPublishedWhatTheyAreOffered() {
        let settings = StubObserveSettings(Settings(pushNotifications: true))
        let recorder = Recorder(makeUseCase(settings: settings, session: StubObserveSession())())

        #expect(recorder.latest.map(\.key) == [
            .pushNotifications,
            .bagOutOfStockNotice,
            .bagPriceIncreases,
            .bagPriceDecreases
        ])
        #expect(recorder.latest.first { $0.key == .pushNotifications }?.isOn == true)
    }

    @Test("A signed-in shopper is published all of them")
    func aSignedInShopperIsPublishedAllOfThem() {
        let recorder = Recorder(
            makeUseCase(settings: StubObserveSettings(), session: StubObserveSession(.shopper))()
        )

        #expect(recorder.latest.map(\.key) == SettingKey.allCases)
    }

    @Test("It publishes again the moment a setting changes")
    func republishesWhenASettingChanges() {
        let settings = StubObserveSettings()
        let recorder = Recorder(makeUseCase(settings: settings, session: StubObserveSession())())

        settings.send(Settings(pushNotifications: true))

        #expect(recorder.published.count == 2)
        #expect(recorder.latest.first { $0.key == .pushNotifications }?.isOn == true)
    }

    @Test("It publishes again the moment the shopper signs in, and again when they sign out")
    func republishesWhenTheSessionChanges() {
        let session = StubObserveSession()
        let recorder = Recorder(makeUseCase(settings: StubObserveSettings(), session: session)())

        session.send(.shopper)
        #expect(recorder.latest.map(\.key) == SettingKey.allCases)

        session.send(.guest)
        #expect(recorder.latest.contains { $0.key.requiresAuthentication } == false)
        #expect(recorder.published.count == 3)
    }
}
