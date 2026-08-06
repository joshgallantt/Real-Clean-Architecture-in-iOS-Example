import Foundation
import Testing
import Session
@testable import Settings

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: in the language of the system, over the
/// record itself. What a shopper is *offered* is `SettingsAcceptanceTests`' subject, and it can only
/// ever assert what a shopper can see; a setting a guest is refused is not one of those, so what a
/// refused write left behind is asserted here, where reading the record directly is the point.
@MainActor
@Suite("Setting one setting")
struct SetSettingUseCaseTests {
    private func makeUseCase(
        repository: StubSettingsRepository,
        session: Session = .guest
    ) -> DefaultSetSettingUseCase {
        DefaultSetSettingUseCase(repository: repository, getSession: StubGetSession(session))
    }

    @Test("A setting the shopper is offered is kept", arguments: SettingKey.offered(signedIn: false))
    func offeredSettingIsKept(_ key: SettingKey) async {
        let repository = StubSettingsRepository()
        let useCase = makeUseCase(repository: repository)

        let outcome = await useCase(key, isOn: !Settings().value(for: key))

        #expect(outcome.failure == nil)
        #expect(repository.settings.value(for: key) == !Settings().value(for: key))
    }

    @Test(
        "A setting the shopper is not offered is refused, and the record is left exactly as it was",
        arguments: [SettingKey.favoritesWaitlistSection, .favoritesBackInStockSection]
    )
    func unofferedSettingIsRefusedAndChangesNothing(_ key: SettingKey) async {
        let before = Settings()
        let repository = StubSettingsRepository(before)
        let useCase = makeUseCase(repository: repository)

        let outcome = await useCase(key, isOn: !before.value(for: key))

        #expect(outcome.failure == .unauthenticated)
        #expect(repository.saves.isEmpty)
        #expect(repository.settings == before)
    }

    @Test("Signing in is what makes the same setting keepable")
    func signingInMakesItKeepable() async {
        let repository = StubSettingsRepository()
        let useCase = makeUseCase(repository: repository, session: .shopper)

        let outcome = await useCase(.favoritesWaitlistSection, isOn: false)

        #expect(outcome.failure == nil)
        #expect(repository.settings.value(for: .favoritesWaitlistSection) == false)
    }

    @Test("A change that could not be kept is not reported as one")
    func aChangeThatCouldNotBeKeptIsNotReported() async {
        let before = Settings()
        let repository = StubSettingsRepository(before)
        repository.whenItCannotKeep = true
        let useCase = makeUseCase(repository: repository)

        let outcome = await useCase(.pushNotifications, isOn: true)

        #expect(outcome.failure == .unavailable)
        #expect(repository.settings == before)
    }

    @Test("Not being signed in and not being able to keep it are different answers")
    func differentAnswers() async {
        let repository = StubSettingsRepository()
        repository.whenItCannotKeep = true

        let refused = await makeUseCase(repository: repository)(.favoritesWaitlistSection, isOn: false)
        let unkept = await makeUseCase(repository: repository)(.pushNotifications, isOn: true)

        #expect(refused.failure == .unauthenticated)
        #expect(unkept.failure == .unavailable)
    }
}
