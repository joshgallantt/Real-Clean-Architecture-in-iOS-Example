import Combine
import Foundation
import Session
import SessionTestSupport
@testable import Settings

@MainActor
final class StubSettingsRepository: SettingsRepository, @unchecked Sendable {
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

/// Every value a publisher put out, in order, so a test can say what changed as well as what is
/// there now.
@MainActor
final class Recorder {
    private(set) var published: [[Setting]] = []
    private var cancellable: AnyCancellable?

    init(_ publisher: AnyPublisher<[Setting], Never>) {
        cancellable = publisher.sink { [weak self] in self?.published.append($0) }
    }

    var latest: [Setting] { published.last ?? [] }
}

// MARK: - Fixtures

extension Result {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}

extension Session {
    static let shopper: Session = .authenticated(
        User(
            id: UserID(rawValue: 42),
            email: Email("shopper@example.com"),
            name: PersonName(first: "Ada", last: nil)
        )
    )
}
