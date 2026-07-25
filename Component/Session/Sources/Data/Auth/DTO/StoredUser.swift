//
//  StoredUser.swift
//  Session
//
//  Created by Josh Gallant on 25/07/2026.
//


public struct StoredUser: Codable, Sendable {
    public let id: Int
    public let email: String
    public let firstName: String
    public let lastName: String
    public let passwordHash: String

    public init(id: Int, email: String, firstName: String, lastName: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.passwordHash = passwordHash
    }
}