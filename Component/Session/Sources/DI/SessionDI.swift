//
//  SessionDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import Foundation
import Session
import SessionData

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
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase

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
        self.userIsLoggedInUseCase = DefaultUserIsLoggedInUseCase(getSession: getSessionUseCase)
    }
}
