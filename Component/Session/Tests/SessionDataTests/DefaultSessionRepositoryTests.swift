import Combine
import Foundation
import Testing
import Session
@testable import SessionData

@MainActor
@Suite("Signing in against the auth system")
/// Fowler, *PoEAA* (2002) — Repository: the translation and the keeping, tested with the real
/// implementation over a stubbed gateway. No rule about what the domain means lives at this level.
struct DefaultSessionRepositoryTests {
    @Test("A successful sign-in keeps the user and their token")
    func successKeepsTheSession() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        _ = await repository.login(email: Email("shopper@example.com"), password: Password("hunter2!!"))

        #expect(store.session.user?.email == Email("shopper@example.com"))
        #expect(store.authToken?.value == "token")
    }

    @Test("A refusal is translated into the domain's word for it, and nothing is kept",
          arguments: [
            (AuthClientError.invalidCredentials, LoginError.invalidCredentials),
            (.networkFailure, .unavailable),
            (.emailAlreadyInUse, .unavailable),
            (.unknown, .unavailable)
          ])
    func translatesLoginFailures(from clientError: AuthClientError, to expected: LoginError) async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.loginResult = .failure(clientError)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.login(email: Email("shopper@example.com"), password: Password("hunter2!!"))

        #expect(result.failure == expected)
        #expect(store.session == .guest)
    }

    @Test("Signing up with an address already in use is said plainly, not as the shop being unavailable")
    func translatesCreateAccountFailures() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.createAccountResult = .failure(.emailAlreadyInUse)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.createAccount(
            name: PersonName(first: "Ada", last: nil),
            email: Email("ada@example.com"),
            password: Password("hunter2!!")
        )

        #expect(result.failure == .emailAlreadyInUse)
    }

    @Test("Every other sign-up refusal is the shop being unavailable rather than a wrong answer",
          arguments: [AuthClientError.invalidCredentials, .networkFailure, .unknown])
    func otherCreateAccountFailures(from clientError: AuthClientError) async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.createAccountResult = .failure(clientError)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.createAccount(
            name: PersonName(first: "Ada", last: nil),
            email: Email("ada@example.com"),
            password: Password("hunter2!!")
        )

        #expect(result.failure == .unavailable)
    }

    @Test("Signing out clears the session even when the auth system will not answer")
    func signOutAlwaysClears() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.logoutResult = .failure(.networkFailure)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)
        await repository.login(email: Email("shopper@example.com"), password: Password("hunter2!!"))

        await repository.logout()

        #expect(store.session == .guest)
        #expect(store.clearCount == 1)
    }
}

// MARK: -

@MainActor
private final class RecordingSessionStore: SessionStore {
    private let subject = CurrentValueSubject<Session, Never>(.guest)
    private(set) var authToken: AuthToken?
    private(set) var clearCount = 0

    var session: Session { subject.value }
    var sessionPublisher: AnyPublisher<Session, Never> { subject.eraseToAnyPublisher() }

    func setUser(_ user: User, token: AuthToken) {
        authToken = token
        subject.send(.authenticated(user))
    }

    func clear() {
        clearCount += 1
        authToken = nil
        subject.send(.guest)
    }
}

private final class StubAuthClient: AuthClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _loginResult: Result<(User, AuthToken), AuthClientError> = .success((.fixture(), .fixture()))
    private var _createAccountResult: Result<(User, AuthToken), AuthClientError> = .success((.fixture(), .fixture()))
    private var _logoutResult: Result<Void, AuthClientError> = .success(())

    var loginResult: Result<(User, AuthToken), AuthClientError> {
        get { lock.withLock { _loginResult } }
        set { lock.withLock { _loginResult = newValue } }
    }

    var createAccountResult: Result<(User, AuthToken), AuthClientError> {
        get { lock.withLock { _createAccountResult } }
        set { lock.withLock { _createAccountResult = newValue } }
    }

    var logoutResult: Result<Void, AuthClientError> {
        get { lock.withLock { _logoutResult } }
        set { lock.withLock { _logoutResult = newValue } }
    }

    func login(email: Email, password: Password) async -> Result<(User, AuthToken), AuthClientError> {
        loginResult
    }

    func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<(User, AuthToken), AuthClientError> {
        createAccountResult
    }

    func logout() async -> Result<Void, AuthClientError> { logoutResult }
}

private extension User {
    static func fixture() -> User {
        User(
            id: UserID(rawValue: 1),
            email: Email("shopper@example.com"),
            name: PersonName(first: "Ada", last: "Lovelace")
        )
    }
}

private extension AuthToken {
    static func fixture(expiresIn seconds: TimeInterval = 3600) -> AuthToken {
        AuthToken(value: "token", expiresAt: Date().addingTimeInterval(seconds))
    }
}

private extension Result where Success == Void, Failure: Equatable {
    var failure: Failure? { if case .failure(let error) = self { error } else { nil } }
}
