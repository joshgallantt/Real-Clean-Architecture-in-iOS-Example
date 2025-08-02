//
//  LoginError.swift
//  User
//
//  Created by Josh Gallant on 02/08/2025.
//

import Foundation

public enum LoginError: Error {
    case invalidCredentials
    case usernameIsEmpty
    case passwordIsEmpty
    case unknown
}

