//
//  AuthToken.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation

public struct AuthToken: Equatable, Sendable {
    let value: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

