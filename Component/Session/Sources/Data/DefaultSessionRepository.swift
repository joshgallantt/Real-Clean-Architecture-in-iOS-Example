import Combine
import Foundation
import Session

public struct DefaultSessionRepository: SessionRepository {
    private let sessionStore: SessionStore
    private let authClient: AuthClient

    public var sessionPublisher: AnyPublisher<Session, Never> {
        sessionStore.sessionPublisher
    }

    public var currentSession: Session {
        sessionStore.session
    }

    public init(sessionStore: SessionStore, authClient: AuthClient) {
        self.sessionStore = sessionStore
        self.authClient = authClient
    }

    public func login(email: Email, password: Password) async -> Result<Void, LoginError> {
        switch await authClient.login(email: email, password: password) {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(Self.loginError(from: error))
        }
    }

    public func createAccount(
        name: PersonName,
        email: Email,
        password: Password
    ) async -> Result<Void, CreateAccountError> {
        switch await authClient.createAccount(name: name, email: email, password: password) {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(Self.createAccountError(from: error))
        }
    }

    public func logout() async {
        _ = await authClient.logout()
        await sessionStore.clear()
    }

    // The auth client's vocabulary becomes the domain's. Anything that is not a specific,
    // actionable answer is the shop not having answered.
    private static func createAccountError(from error: AuthClientError) -> CreateAccountError {
        switch error {
        case .emailAlreadyInUse:
            .emailAlreadyInUse
        case .invalidCredentials, .networkFailure, .unknown:
            .unavailable
        }
    }

    private static func loginError(from error: AuthClientError) -> LoginError {
        switch error {
        case .invalidCredentials:
            .invalidCredentials
        case .emailAlreadyInUse, .networkFailure, .unknown:
            .unavailable
        }
    }
}
