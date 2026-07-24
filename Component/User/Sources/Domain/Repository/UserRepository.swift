//
//  UserRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import Combine

public protocol UserRepository {
    @MainActor
    var loggedInPublisher: AnyPublisher<Bool, Never> { get }
    
    @MainActor
    func login(username: String, password: String) async -> Result<Void, LoginError>
    
    @MainActor
    func logout() async
}

