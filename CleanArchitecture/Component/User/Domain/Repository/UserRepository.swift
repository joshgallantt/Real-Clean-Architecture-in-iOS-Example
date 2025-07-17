//
//  UserRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//


import Combine

protocol UserRepository {
    var isLoggedIn: Bool { get }
    var loggedInPublisher: AnyPublisher<Bool, Never> { get }
    func login(username: String, password: String) async -> Bool
    func logout() async
}
