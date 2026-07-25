//
//  User.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

public struct User: Equatable, Sendable {
    public let id: Int
    public let email: String
    public let firstName: String
    public let lastName: String

    public init(id: Int, email: String, firstName: String, lastName: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
}
