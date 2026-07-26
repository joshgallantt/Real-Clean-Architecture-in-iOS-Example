//
//  SessionRepository.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import Combine

public protocol SessionRepository: Sendable {
    @MainActor
    var sessionPublisher: AnyPublisher<Session, Never> { get }

    @MainActor
    var currentSession: Session { get }

    func login(email: String, password: String) async -> Result<Void, LoginError>

    func createAccount(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<Void, CreateAccountError>

    func logout() async
}
