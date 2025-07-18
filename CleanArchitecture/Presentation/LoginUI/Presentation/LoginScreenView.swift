//
//  LoginScreenView.swift
//  CleanArchitecture
//
//  Created by Josh Gallant on 14/07/2025.
//

import SwiftUI

struct LoginScreenView: View {
    @ObservedObject var viewModel: LoginScreenViewModel

    init(viewModel: LoginScreenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            TextField("Username", text: $viewModel.username)
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
    }
}
