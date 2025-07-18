//
//  UserDI.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import Foundation

public struct UserDI {
    let userRepository: UserRepository
    let userLoginUseCase: UserLoginUseCase
    let userIsLoggedInUseCase: UserIsLoggedInUseCase
    let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
        self.userLoginUseCase = UserLoginUseCase(userRepository: userRepository)
        self.userIsLoggedInUseCase = UserIsLoggedInUseCase(userRepository: userRepository)
        self.observeUserIsLoggedInUseCase = ObserveUserIsLoggedInUseCase(userRepository: userRepository)
    }
}
