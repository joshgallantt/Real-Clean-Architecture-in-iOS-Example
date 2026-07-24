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

    func login(username: String, password: String) async -> Result<Void, LoginError>

    func logout() async
}
