//
//  UserDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import Foundation
import UserDomain
import UserData

public struct UserDI {
    // MARK: - Data Sources
    private let userSession: UserSession
    private let authClient: AuthClient

    // MARK: - Repository
    private let userRepository: UserRepository

    // MARK: - Use Cases
    public let userLoginUseCase: UserLoginUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase

    // MARK: - Initializer

    @MainActor
    public init(
        userSession: UserSession = DefaultUserSession(),
        authClient: AuthClient = FakeAuthClient()
    ) {
        self.userSession = userSession
        self.authClient = authClient

        let repository = DefaultUserRepository(session: userSession, authClient: authClient)
        self.userRepository = repository
        
        self.userLoginUseCase = DefaultUserLoginUseCase(userRepository: repository)
        self.userIsLoggedInUseCase = DefaultUserIsLoggedInUseCase(userRepository: repository)
        self.observeUserIsLoggedInUseCase = DefaultObserveUserIsLoggedInUseCase(userRepository: repository)
    }
}
