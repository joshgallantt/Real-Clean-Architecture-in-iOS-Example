//
//  ObserveUserIsLoggedInUseCase.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Combine

public struct ObserveUserIsLoggedInUseCase {
    let userRepository: UserRepository
    func execute() -> AnyPublisher<Bool, Never> {
        userRepository.loggedInPublisher
    }
}
