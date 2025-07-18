//
//  DefaultUserRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine
import Foundation

final class DefaultUserRepository: UserRepository {
    private let session: UserSession
    private let authClient: AuthClient

    var isLoggedIn: Bool {
        session.isLoggedIn
    }

    var loggedInPublisher: AnyPublisher<Bool, Never> {
        session.isLoggedInPublisher
    }

    init(session: UserSession, authClient: AuthClient) {
        self.session = session
        self.authClient = authClient
    }

    func login(username: String, password: String) async -> Bool {
        guard let (user, token) = await authClient.login(username: username, password: password) else {
            return false
        }
        await MainActor.run {
            session.setUser(user, token: token)
        }
        return true
    }
    
    func logout() async {
        await authClient.logout()
        await MainActor.run { session.clear() }
    }
}
