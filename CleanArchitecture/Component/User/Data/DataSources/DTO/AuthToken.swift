//
//  AuthToken.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 17/07/2025.
//


import Foundation

struct AuthToken: Equatable {
    let value: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}
