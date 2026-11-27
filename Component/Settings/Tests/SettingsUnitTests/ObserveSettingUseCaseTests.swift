import Combine
import Foundation
import Testing
@testable import Settings

@MainActor
@Suite("Observing whether one setting is on")
struct ObserveSettingUseCaseTests {
    @Test("A setting nobody has touched is worth its default", arguments: SettingKey.allCases)
    func untouched(_ key: SettingKey) {
        var published: [Bool] = []
        let watching = DefaultObserveSettingUseCase(repository: StubSettingsRepository())(key)
            .sink { published.append($0) }

        #expect(published == [Settings().value(for: key)])
        watching.cancel()
    }

    @Test("It publishes again the moment that setting changes, and not when another one does")
    func republishesForItsOwnKeyOnly() {
        let repository = StubSettingsRepository()
        var published: [Bool] = []
        let watching = DefaultObserveSettingUseCase(repository: repository)(.bagChangesSection)
            .sink { published.append($0) }

        repository.send(Settings([.pushNotifications: true]))
        repository.send(Settings([.pushNotifications: true, .bagChangesSection: false]))

        #expect(published == [true, false])
        watching.cancel()
    }
}
