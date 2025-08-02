//
//  DefaultUserRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine
import Foundation
import UserDomain

public final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient

    public var loggedInPublisher: AnyPublisher<Bool, Never> {
        session.isLoggedInPublisher
    }

    public init(session: UserSession, authClient: AuthClient) {
        self.session = session
        self.authClient = authClient
    }

    @MainActor
    public func login(username: String, password: String) async -> Result<Void, LoginError> {
        let result = await authClient.login(username: username, password: password)
        switch result {
        case let .success((user, token)):
            session.setUser(user, token: token)
            return .success(())
        case .failure(let error):
            return .failure(mapAuthClientErrorToLoginError(error))
        }
    }

    @MainActor
    public func logout() async {
        _ = await authClient.logout()
        session.clear()
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

