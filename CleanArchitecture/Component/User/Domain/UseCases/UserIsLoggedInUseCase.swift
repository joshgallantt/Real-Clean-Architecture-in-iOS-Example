//
//  UserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


struct UserIsLoggedInUseCase {
    let userRepository: UserRepository
    func execute() -> Bool {
        userRepository.isLoggedIn
    }
}
