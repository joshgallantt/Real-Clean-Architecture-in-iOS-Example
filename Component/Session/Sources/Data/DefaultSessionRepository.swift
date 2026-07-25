//
//  DefaultSessionRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

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

    public func login(email: String, password: String) async -> Result<Void, LoginError> {
        let result = await authClient.login(email: email, password: password)
        switch result {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(mapAuthClientErrorToLoginError(error))
        }
    }

    public func createAccount(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError> {
        let result = await authClient.createAccount(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        )
        switch result {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(mapAuthClientErrorToCreateAccountError(error))
        }
    }

    private func mapAuthClientErrorToCreateAccountError(_ error: AuthClientError) -> CreateAccountError {
        switch error {
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .invalidCredentials, .networkFailure, .unknown:
            return .unknown
        }
    }

    public func logout() async {
        _ = await authClient.logout()
        await sessionStore.clear()
    }

    private func mapAuthClientErrorToLoginError(_ error: AuthClientError) -> LoginError {
        switch error {
        case .invalidCredentials:
            return .invalidCredentials
        case .emailAlreadyInUse, .networkFailure, .unknown:
            return .unknown
        }
    }
}
