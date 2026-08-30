import Combine
import Session

public final class StubObserveSession: ObserveSessionUseCase, @unchecked Sendable {
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

/// A spy rather than a stub: it answers *and* records that it was asked.
///
/// The kind is in the name because the kind is what the test using it verifies.
/// One copy of this had been called `StubObserveSession` while counting its
/// calls, which reads in review as a type that does not do the thing the test
/// then asserts about.
@MainActor
public final class SpyObserveSession: ObserveSessionUseCase, @unchecked Sendable {
    private let subject: CurrentValueSubject<Session, Never>
    public private(set) var callCount = 0

    public init(initial: Session = .guest) {
        subject = CurrentValueSubject(initial)
    }

    public func callAsFunction() -> AnyPublisher<Session, Never> {
        callCount += 1
        return subject.eraseToAnyPublisher()
    }

    public func send(_ session: Session) {
        subject.send(session)
    }
}

@MainActor
public final class SpyLogout: LogoutUseCase, @unchecked Sendable {
    public init() {}

    public private(set) var callCount = 0

    public func callAsFunction() async {
        callCount += 1
    }
}

@MainActor
public final class StubLogin: LoginUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<Void, LoginError> = .success(())
    public private(set) var calls: [(email: Email, password: Password)] = []

    public func callAsFunction(email: Email, password: Password) async -> Result<Void, LoginError> {
        calls.append((email, password))
        return result
    }
}

@MainActor
public final class StubCreateAccount: CreateAccountUseCase, @unchecked Sendable {
    public init() {}

    public var result: Result<Void, CreateAccountError> = .success(())
    public private(set) var calls: [(name: PersonName, email: Email, password: Password)] = []

    public func callAsFunction(name: PersonName, email: Email, password: Password) async -> Result<Void, CreateAccountError> {
        calls.append((name, email, password))
        return result
    }
}

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
public final class StubGetSession: GetSessionUseCase, @unchecked Sendable {
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
