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
    public let userLoginUseCase: UserLoginUseCaseProtocol
    public let userIsLoggedInUseCase: UserIsLoggedInUseCaseProtocol
    public let observeUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol

    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
        self.userLoginUseCase = UserLoginUseCase(userRepository: userRepository)
        self.userIsLoggedInUseCase = UserIsLoggedInUseCase(userRepository: userRepository)
        self.observeUserIsLoggedInUseCase = ObserveUserIsLoggedInUseCase(userRepository: userRepository)
    }
}
