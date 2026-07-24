//
//  UserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine

public protocol UserIsLoggedInUseCase {
    @MainActor
    func execute() async -> Bool
}

public struct DefaultUserIsLoggedInUseCase: UserIsLoggedInUseCase {
    let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    @MainActor
    public func execute() async -> Bool {
        await withCheckedContinuation { continuation in
            let cancellable = userRepository.loggedInPublisher
                .first()
                .sink { isLoggedIn in
                    continuation.resume(returning: isLoggedIn)
                }
            
            _ = cancellable
        }
    }
}
