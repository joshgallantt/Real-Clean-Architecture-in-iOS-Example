//
//  LoginScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

struct LoginScreenView: View {
    let userLogin: UserLoginUseCase

    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $username)
            SecureField("Password", text: $password)
            if isLoading {
                ProgressView()
            } else {
                Button("Login") {
                    Task {
                        isLoading = true
                        let success = await userLogin.execute(username: username, password: password)
                        isLoading = false
                        if success {
                            print("Logged in!")
                        } else {
                            error = "Login failed"
                        }
                    }
                }
            }
            if let error {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
    }
}
