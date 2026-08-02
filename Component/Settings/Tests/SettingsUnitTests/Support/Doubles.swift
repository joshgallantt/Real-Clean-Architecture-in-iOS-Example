import Combine
import Foundation
import Session
@testable import Settings

@MainActor
final class StubObserveSettings: ObserveSettingsUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Settings, Never>

    init(_ settings: Settings = Settings()) {
        subject = CurrentValueSubject(settings)
    }

    func callAsFunction() -> AnyPublisher<Settings, Never> { subject.eraseToAnyPublisher() }

    func send(_ settings: Settings) { subject.send(settings) }
}

@MainActor
final class StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Session, Never>

    init(_ session: Session = .guest) {
        subject = CurrentValueSubject(session)
    }

    func callAsFunction() -> AnyPublisher<Session, Never> { subject.eraseToAnyPublisher() }

    func send(_ session: Session) { subject.send(session) }
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

extension Session {
    static let shopper: Session = .authenticated(
        User(
            id: UserID(rawValue: 42),
            email: Email("shopper@example.com"),
            name: PersonName(first: "Ada", last: nil)
        )
    )
}
