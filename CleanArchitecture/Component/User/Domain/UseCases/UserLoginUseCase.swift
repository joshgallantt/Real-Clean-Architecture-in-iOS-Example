//
//  UserLoginUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


public struct UserLoginUseCase {
    let userRepository: UserRepository
    func execute(username: String, password: String) async -> Bool {
        await userRepository.login(username: username, password: password)
    }
}
