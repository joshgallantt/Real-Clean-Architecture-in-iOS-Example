//
//  DefaultUserRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine
import Foundation
import UserDomain

@MainActor
public final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient

    public var isLoggedIn: Bool {
        session.isLoggedIn
    }

    public var loggedInPublisher: AnyPublisher<Bool, Never> {
        session.isLoggedInPublisher
    }

    public init(session: UserSession, authClient: AuthClient) {
        self.session = session
        self.authClient = authClient
    }

    public func login(username: String, password: String) async -> Bool {
        guard let (user, token) = await authClient.login(username: username, password: password) else {
            return false
        }
        session.setUser(user, token: token)
        return true
    }

    public func logout() async {
        await authClient.logout()
        session.clear()
    }
}


