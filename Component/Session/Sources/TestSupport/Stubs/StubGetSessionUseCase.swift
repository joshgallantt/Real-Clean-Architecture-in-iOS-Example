import Combine
import Session

/// Stand-ins for the Session component's use cases, published so that every
/// package whose tests need somebody signed in shares one definition.
///
/// Session is the one thing nearly every journey touches, so before this
/// existed the same stub had been written ten times over — each copy private to
/// its own file, so nothing collided and nothing could be found either. A test
/// target cannot be shared across packages in SwiftPM, so shared test code has
/// to be an ordinary module; the architecture rules state that this one is
/// visible to tests alone, which is what keeps it out of the shipping app.
///
/// Both doubles can be built around a subject the test already holds, so a
/// journey that signs somebody in partway through moves the getter and the
/// publisher together.
@MainActor
public final class StubGetSessionUseCase: GetSessionUseCase {
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

    /// Pushes a new session, for a test that changes who is signed in partway
    /// through rather than setting it up once.
    public func send(_ session: Session) {
        sessions.send(session)
    }

    /// Readable and settable, for a unit test that simply wants a different
    /// answer next time.
    public var session: Session {
        get { sessions.value }
        set { sessions.send(newValue) }
    }

    @MainActor
    public func callAsFunction() -> Session { sessions.value }
}
