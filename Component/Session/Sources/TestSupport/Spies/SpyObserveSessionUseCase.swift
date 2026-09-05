import Combine
import Session

/// A spy rather than a stub: it answers *and* records that it was asked.
///
/// The kind is in the name because the kind is what the test using it verifies.
///
/// There were two of these — a `SpyObserveSessionUseCase` that counted its calls and a
/// `SpyObserveSessionUseCase` that carried the richer set of initialisers — answering
/// the same protocol the same way, so a test got a counter or did not depending
/// on which name it happened to reach for. This is both.
@MainActor
public final class SpyObserveSessionUseCase: ObserveSessionUseCase {
    public let sessions: CurrentValueSubject<Session, Never>
    public private(set) var callCount = 0

    public init(_ session: Session = .guest) {
        self.sessions = CurrentValueSubject(session)
    }

    public init(sessions: CurrentValueSubject<Session, Never>) {
        self.sessions = sessions
    }

    public init(initial: Session) {
        self.sessions = CurrentValueSubject(initial)
    }

    public var session: Session {
        get { sessions.value }
        set { sessions.send(newValue) }
    }

    public func send(_ session: Session) {
        sessions.send(session)
    }

    public func callAsFunction() -> AnyPublisher<Session, Never> {
        callCount += 1
        return sessions.eraseToAnyPublisher()
    }
}
