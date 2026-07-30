import Foundation
import Session
import SessionData

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct SessionDI {
    // MARK: - Data Sources
    private let sessionStore: SessionStore
    private let authClient: AuthClient

    // MARK: - Repository
    private let sessionRepository: SessionRepository

    // MARK: - Use Cases
    public let loginUseCase: LoginUseCase
    public let createAccountUseCase: CreateAccountUseCase
    public let logoutUseCase: LogoutUseCase
    public let getSessionUseCase: GetSessionUseCase
    public let observeSessionUseCase: ObserveSessionUseCase

    // MARK: - Initializer

    @MainActor
    public init(
        sessionStore: SessionStore,
        authClient: AuthClient
    ) {
        self.sessionStore = sessionStore
        self.authClient = authClient

        let repository = DefaultSessionRepository(sessionStore: sessionStore, authClient: authClient)
        self.sessionRepository = repository

        self.loginUseCase = DefaultLoginUseCase(sessionRepository: repository)
        self.createAccountUseCase = DefaultCreateAccountUseCase(sessionRepository: repository)
        self.logoutUseCase = DefaultLogoutUseCase(sessionRepository: repository)
        self.getSessionUseCase = DefaultGetSessionUseCase(sessionRepository: repository)
        self.observeSessionUseCase = DefaultObserveSessionUseCase(sessionRepository: repository)
    }
}
