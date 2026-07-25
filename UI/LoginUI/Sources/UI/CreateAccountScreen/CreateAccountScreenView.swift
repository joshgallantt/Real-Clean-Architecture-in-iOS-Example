import SwiftUI

public struct CreateAccountScreenView: View {
    @StateObject private var viewModel: CreateAccountScreenViewModel

    public init(viewModel: @autoclosure @escaping () -> CreateAccountScreenViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: 20) {
            TextField("First name", text: $viewModel.firstName)
                .textContentType(.givenName)
            TextField("Last name", text: $viewModel.lastName)
                .textContentType(.familyName)
            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            SecureField("Password", text: $viewModel.password)
                .textContentType(.newPassword)

            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Create Account") {
                    Task { await viewModel.createAccount() }
                }
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .sizeToFitSheet()
    }
}
