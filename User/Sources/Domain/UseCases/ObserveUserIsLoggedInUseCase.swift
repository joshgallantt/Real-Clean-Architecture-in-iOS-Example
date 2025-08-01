//
//  ObserveUserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Combine

public protocol ObserveUserIsLoggedInUseCase {
    @MainActor
    func execute() -> AnyPublisher<Bool, Never>
}

public struct DefaultObserveUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCase {
    let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    @MainActor
    public func execute() -> AnyPublisher<Bool, Never> {
        userRepository.loggedInPublisher
    }
}
