//
//  User.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//

import Foundation

public struct User: Equatable, Sendable {
    public let id: UUID
    public let username: String

    public init(id: UUID, username: String) {
        self.id = id
        self.username = username
    }
}
