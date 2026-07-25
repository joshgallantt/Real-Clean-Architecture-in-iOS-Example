//
//  LoginScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

public struct LoginScreenView: View {
    @StateObject private var viewModel: LoginScreenViewModel

    public init(
        viewModel: @autoclosure @escaping () -> LoginScreenViewModel
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            SecureField("Password", text: $viewModel.password)
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Login") {
                    Task {
                        await viewModel.login()
                    }
                }
            }
            if let error = viewModel.error {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .sizeToFitSheet()
    }
}
