import Combine
import Foundation
import Session
@testable import AccountUI

@MainActor
final class StubGetSession: GetSessionUseCase, @unchecked Sendable {
    var session: Session = .guest

    func callAsFunction() -> Session { session }
}

@MainActor
final class SpyObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Session, Never>
    private(set) var callCount = 0

    init(initial: Session = .guest) {
        subject = CurrentValueSubject(initial)
    }

    func callAsFunction() -> AnyPublisher<Session, Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    func send(_ session: Session) {
        subject.send(session)
    }
}

@MainActor
final class SpyLogout: LogoutUseCase, @unchecked Sendable {
    private(set) var callCount = 0

    func callAsFunction() async {
        callCount += 1
    }
}

// MARK: - Fixtures

extension User {
    static func fixture(id: Int = 1, first: String = "Ada") -> User {
        User(
            id: UserID(rawValue: id),
            email: Email("\(first.lowercased())@example.com"),
            name: PersonName(first: first, last: nil)
        )
    }
}
