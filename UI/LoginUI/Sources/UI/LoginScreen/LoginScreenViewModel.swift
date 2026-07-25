//
//  LoginScreenViewModel.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 18/07/2025.
//

import Foundation
import Combine
import Session

@MainActor
public final class LoginScreenViewModel: ObservableObject {
    private let loginUseCase: LoginUseCase
    private let onAuthenticated: () -> Void

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    public init(loginUseCase: LoginUseCase, onAuthenticated: @escaping () -> Void) {
        self.loginUseCase = loginUseCase
        self.onAuthenticated = onAuthenticated
    }

    func login() async {
        isLoading = true
        defer { isLoading = false }
        error = nil

        let result = await loginUseCase(email: email, password: password)
        switch result {
        case .success:
            onAuthenticated()
        case .failure(let loginError):
            self.error = mapLoginErrorToMessage(loginError)
        }
    }

    private func mapLoginErrorToMessage(_ error: LoginError) -> String {
        switch error {
        case .emailIsEmpty:
            return "Email is required."
        case .passwordIsEmpty:
            return "Password is required."
        case .invalidCredentials:
            return "Invalid email or password."
        case .unknown:
            return "An unknown error occurred. Please try again later."
        }
    }
}
