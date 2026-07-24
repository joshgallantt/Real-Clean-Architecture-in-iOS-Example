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
    case networkFailure
    case unknown
}

public protocol AuthClient: Sendable {
    func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError>
    func logout() async -> Result<Void, AuthClientError>
}

public actor FakeAuthClient: AuthClient {
    public private(set) var lastLoginToken: AuthToken?
    public private(set) var exampleExpiry: TimeInterval

    public init(
        lastLoginToken: AuthToken?,
        exampleExpiry: TimeInterval
    ) {
        self.lastLoginToken = lastLoginToken
        self.exampleExpiry = exampleExpiry
    }
    
    public func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if username == "test", password == "test" {
            return .failure(.invalidCredentials)
        }
        guard !username.isEmpty, !password.isEmpty else {
            return .failure(.invalidCredentials)
        }
        
        let expiry = Date().addingTimeInterval(exampleExpiry)
        let token = AuthToken(value: UUID().uuidString, expiresAt: expiry)
        lastLoginToken = token
        let user = User(id: abs(username.hashValue % 1000), username: username, email: "\(username)@example.com", firstName: username.capitalized, lastName: "")
        return .success((user, token))
    }

    public func logout() async -> Result<Void, AuthClientError> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        lastLoginToken = nil
        return .success(())
    }
}

