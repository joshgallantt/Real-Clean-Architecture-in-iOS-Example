//
//  DefaultSessionRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine
import Foundation
import Session

public final class DefaultSessionRepository: SessionRepository {
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

    public func login(username: String, password: String) async -> Result<Void, LoginError> {
        let result = await authClient.login(username: username, password: password)
        switch result {
        case let .success((user, token)):
            await sessionStore.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(mapAuthClientErrorToLoginError(error))
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
        case .networkFailure, .unknown:
            return .unknown
        }
    }
}
