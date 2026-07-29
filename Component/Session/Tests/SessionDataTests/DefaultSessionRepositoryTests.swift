import Combine
import Foundation
import Testing
import Session
@testable import SessionData

/// The boundary where an auth system's vocabulary becomes the domain's. Everything here
/// is about translation and about what gets kept — no rule about what a valid email or
/// password is lives at this level.
@MainActor
@Suite("Signing in against the auth system")
struct DefaultSessionRepositoryTests {

    @Test("A successful sign-in keeps the user and their token")
    func successKeepsTheSession() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        _ = await repository.login(email: "shopper@example.com", password: "hunter2!!")

        #expect(store.session.user?.email == "shopper@example.com")
        #expect(store.authToken?.value == "token")
    }

    @Test("A refusal is translated into the domain's word for it, and nothing is kept",
          arguments: [
            (AuthClientError.invalidCredentials, LoginError.invalidCredentials),
            (.networkFailure, .unknown),
            (.emailAlreadyInUse, .unknown),
            (.unknown, .unknown)
          ])
    func translatesLoginFailures(from clientError: AuthClientError, to expected: LoginError) async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.loginResult = .failure(clientError)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.login(email: "shopper@example.com", password: "hunter2!!")

        #expect(result.failure == expected)
        #expect(store.session == .guest)
    }

    @Test("Signing up with an address already in use is said plainly, not as an unknown error")
    func translatesCreateAccountFailures() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.createAccountResult = .failure(.emailAlreadyInUse)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.createAccount(
            firstName: "Ada", lastName: "", email: "ada@example.com", password: "hunter2!!"
        )

        #expect(result.failure == .emailAlreadyInUse)
    }

    @Test("Every other sign-up refusal is an unknown error rather than a wrong one",
          arguments: [AuthClientError.invalidCredentials, .networkFailure, .unknown])
    func otherCreateAccountFailures(from clientError: AuthClientError) async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.createAccountResult = .failure(clientError)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)

        let result = await repository.createAccount(
            firstName: "Ada", lastName: "", email: "ada@example.com", password: "hunter2!!"
        )

        #expect(result.failure == .unknown)
    }

    @Test("Signing out clears the session even when the auth system will not answer")
    func signOutAlwaysClears() async {
        let store = RecordingSessionStore()
        let client = StubAuthClient()
        client.logoutResult = .failure(.networkFailure)
        let repository = DefaultSessionRepository(sessionStore: store, authClient: client)
        await repository.login(email: "shopper@example.com", password: "hunter2!!")

        await repository.logout()

        // A shopper who taps Log Out must end up logged out. Leaving them signed in
        // because a server did not reply is the wrong way to fail.
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

    func login(email: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        loginResult
    }

    func createAccount(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<(User, AuthToken), AuthClientError> {
        createAccountResult
    }

    func logout() async -> Result<Void, AuthClientError> { logoutResult }
}

private extension User {
    static func fixture() -> User {
        User(id: 1, email: "shopper@example.com", firstName: "Ada", lastName: "Lovelace")
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
