//
//  AuthClient.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation

protocol AuthClient {
    func login(username: String, password: String) async -> (User, AuthToken)?
    func logout() async
}


final class FakeAuthClient: AuthClient {
    private(set) var lastLoginToken: AuthToken? = nil
    private(set) var exampleExpiry: TimeInterval = 60

    func login(username: String, password: String) async -> (User, AuthToken)? {
        try? await Task.sleep(nanoseconds: 500_000_000)
        guard !username.isEmpty, !password.isEmpty else { return nil }
        let expiry = Date().addingTimeInterval(exampleExpiry)
        let token = AuthToken(value: UUID().uuidString, expiresAt: expiry)
        lastLoginToken = token
        return (User(id: UUID(), username: username), token)
    }

    func logout() async {
        try? await Task.sleep(nanoseconds: 100_000_000)
        lastLoginToken = nil
    }
}
