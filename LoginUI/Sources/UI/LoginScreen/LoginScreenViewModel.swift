//
//  LoginScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import Foundation
import Combine
import UserDomain

@MainActor
public final class LoginScreenViewModel: ObservableObject {
    private let userLogin: UserLoginUseCase

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    public init(userLogin: UserLoginUseCase) {
        self.userLogin = userLogin
    }

    func login() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        let result = await userLogin.execute(username: username, password: password)
        switch result {
        case .success:
            break
        case .failure(let loginError):
            self.error = mapLoginErrorToMessage(loginError)
        }
    }

    private func mapLoginErrorToMessage(_ error: LoginError) -> String {
        switch error {
        case .usernameIsEmpty:
            return "Username is required."
        case .passwordIsEmpty:
            return "Password is required."
        case .invalidCredentials:
            return "Invalid username or password."
        case .unknown:
            return "An unknown error occurred. Please try again later."
        }
    }
}
