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
    @Published var loginSuccess: Bool = false

    public init(userLogin: UserLoginUseCase) {
        self.userLogin = userLogin
    }

    func login() async {
        isLoading = true
        error = nil
        let success = await userLogin.execute(username: username, password: password)
        isLoading = false
        if success {
            loginSuccess = true
        } else {
            error = "Login failed"
        }
    }
}
