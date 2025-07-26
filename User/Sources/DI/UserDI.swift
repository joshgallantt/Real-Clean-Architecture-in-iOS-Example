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
    public let userRepository: UserRepository
    public let userLoginUseCase: UserLoginUseCase
    public let userIsLoggedInUseCase: UserIsLoggedInUseCase
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase

    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
        self.userLoginUseCase = DefaultUserLoginUseCase(userRepository: userRepository)
        self.userIsLoggedInUseCase = DefaultUserIsLoggedInUseCase(userRepository: userRepository)
        self.observeUserIsLoggedInUseCase = DefaultObserveUserIsLoggedInUseCase(userRepository: userRepository)
    }
}
