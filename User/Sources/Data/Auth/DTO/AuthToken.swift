//
//  AuthToken.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation

public struct AuthToken: Equatable, Sendable {
    public let value: String
    public let expiresAt: Date
    
    public init(value: String, expiresAt: Date) {
        self.value = value
        self.expiresAt = expiresAt
    }
    
    public var isExpired: Bool {
        Date() >= expiresAt
    }
}

