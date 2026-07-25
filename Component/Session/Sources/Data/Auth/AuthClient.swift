//
//  AuthClient.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Foundation
import Session

public enum AuthClientError: Error, Equatable {
    case invalidCredentials
    case emailAlreadyInUse
    case networkFailure
    case unknown
}

public protocol AuthClient: Sendable {
    func login(email: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
    func createAccount(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}
