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
    private let userRepository: UserRepository
    public let userLoginUseCase: UserLoginUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase

    @MainActor
    public init() {
        self.userRepository = UserDI.makeRepository()
        self.userLoginUseCase = DefaultUserLoginUseCase(userRepository: userRepository)
        self.userIsLoggedInUseCase = DefaultUserIsLoggedInUseCase(userRepository: userRepository)
        self.observeUserIsLoggedInUseCase = DefaultObserveUserIsLoggedInUseCase(userRepository: userRepository)
    }
    
    @MainActor
    private static func makeRepository() -> UserRepository {
        DefaultUserRepository(
            session: DefaultUserSession(),
            authClient: FakeAuthClient()
        )
    }
}

