//
//  UserLoginUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

public protocol UserLoginUseCaseProtocol {
    @MainActor
    func execute(username: String, password: String) async -> Bool
}

public struct UserLoginUseCase: UserLoginUseCaseProtocol {
    let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    @MainActor
    public func execute(username: String, password: String) async -> Bool {
        await userRepository.login(username: username, password: password)
    }
}
