//
//  FakeAuthClient.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Foundation
import CryptoKit
import Session

/// Local auth client that bypasses any backend. Accounts are stored on-device in a
/// `UserStore`: Create Account registers a user, and Login only succeeds for an email
/// that has been registered with the matching password. Tokens are minted locally.
public struct FakeAuthClient: AuthClient {
    private let userStore: UserStore
    private let tokenLifetime: TimeInterval

    public init(userStore: UserStore, tokenLifetime: TimeInterval) {
        self.userStore = userStore
        self.tokenLifetime = tokenLifetime
    }

    public func login(email: String, password: String) async -> Result<(User, AuthToken), AuthClientError> {
        guard isValidEmail(email), !password.isEmpty else {
            return .failure(.invalidCredentials)
        }
        guard let record = userStore.find(email: email) else {
            return .failure(.invalidCredentials)
        }
        guard record.passwordHash == hash(password) else {
            return .failure(.invalidCredentials)
        }
        return .success(makeSession(from: record))
    }

    public func createAccount(
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async -> Result<(User, AuthToken), AuthClientError> {
        guard isValidEmail(email), !password.isEmpty else {
            return .failure(.unknown)
        }
        guard userStore.find(email: email) == nil else {
            return .failure(.emailAlreadyInUse)
        }
        let record = StoredUser(
            id: stableId(for: email),
            email: email,
            firstName: firstName,
            lastName: lastName,
            passwordHash: hash(password)
        )
        userStore.save(record)
        return .success(makeSession(from: record))
    }

    public func logout() async -> Result<Void, AuthClientError> {
        .success(())
    }

    private func makeSession(from record: StoredUser) -> (User, AuthToken) {
        let user = User(
            id: record.id,
            email: record.email,
            firstName: record.firstName,
            lastName: record.lastName
        )
        let token = AuthToken(value: UUID().uuidString, expiresAt: Date().addingTimeInterval(tokenLifetime))
        return (user, token)
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
    }

    private func hash(_ password: String) -> String {
        SHA256.hash(data: Data(password.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    /// Deterministic id so the same email always maps to the same user (and wishlist).
    private func stableId(for email: String) -> Int {
        var hash = 5381
        for byte in email.lowercased().utf8 {
            hash = (hash &* 33) &+ Int(byte)
        }
        return hash & .max
    }
}
