import Combine
import Session

@MainActor
public final class StubObserveSession: ObserveSessionUseCase {
    public let sessions: CurrentValueSubject<Session, Never>

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

    @MainActor
    public func callAsFunction() -> AnyPublisher<Session, Never> { sessions.eraseToAnyPublisher() }
}
