//
//  UserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

public protocol UserIsLoggedInUseCaseProtocol {
    @MainActor
    func execute() -> Bool
}

public struct UserIsLoggedInUseCase: UserIsLoggedInUseCaseProtocol {
    let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    @MainActor
    public func execute() -> Bool {
        userRepository.isLoggedIn
    }
}
