import Combine
import Foundation
@testable import Settings

@MainActor
final class StubSettingsRepository: SettingsRepository {
    private let subject: CurrentValueSubject<Settings, Never>

    /// Set to have `save` throw, so a test can say what a store that will not keep something means
    /// to the shopper without needing a store that genuinely cannot.
    var whenItCannotKeep = false
    private(set) var saves: [Settings] = []

    init(_ settings: Settings = Settings()) {
        subject = CurrentValueSubject(settings)
    }

    var settings: Settings { subject.value }

    var settingsPublisher: AnyPublisher<Settings, Never> { subject.eraseToAnyPublisher() }

    func save(_ settings: Settings) async throws {
        if whenItCannotKeep { throw CouldNotKeep() }
        saves.append(settings)
        subject.send(settings)
    }

    func send(_ settings: Settings) { subject.send(settings) }

    struct CouldNotKeep: Error {}
}
