//
//  AuthClient.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Foundation
import UserDomain

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
    public typealias ErrorGenerator = () -> AuthClientError?
    
    private let errorGenerator: ErrorGenerator
    private(set) var lastLoginToken: AuthToken? = nil
    private(set) var exampleExpiry: TimeInterval = 60

    public init(
        lastLoginToken: AuthToken? = nil,
        exampleExpiry: TimeInterval = 60,
        errorGenerator: @escaping ErrorGenerator = { nil }
    ) {
        self.lastLoginToken = lastLoginToken
        self.exampleExpiry = exampleExpiry
        self.errorGenerator = errorGenerator
    }
    
    public func login(username: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if username == "test", password == "test" {
            return .failure(.invalidCredentials)
        }
        if let error = errorGenerator() {
            return .failure(error)
        }
        guard !username.isEmpty, !password.isEmpty else {
            return .failure(.invalidCredentials)
        }
        
        let expiry = Date().addingTimeInterval(exampleExpiry)
        let token = AuthToken(value: UUID().uuidString, expiresAt: expiry)
        lastLoginToken = token
        return .success((User(id: UUID(), username: username), token))
    }

    public func logout() async -> Result<Void, AuthClientError> {
        try? await Task.sleep(nanoseconds: 500_000_000)
        if let error = errorGenerator() {
            return .failure(error)
        }
        lastLoginToken = nil
        return .success(())
    }
}
