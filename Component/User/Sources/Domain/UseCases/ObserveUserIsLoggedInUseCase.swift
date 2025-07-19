//
//  ObserveUserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Combine

public protocol ObserveUserIsLoggedInUseCaseProtocol {
    @MainActor
    func execute() -> AnyPublisher<Bool, Never>
}

public struct ObserveUserIsLoggedInUseCase: ObserveUserIsLoggedInUseCaseProtocol {
    let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    @MainActor
    public func execute() -> AnyPublisher<Bool, Never> {
        userRepository.loggedInPublisher
    }
}
