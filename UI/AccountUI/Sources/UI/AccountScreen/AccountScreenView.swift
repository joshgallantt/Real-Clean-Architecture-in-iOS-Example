import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let loginButton: AnyView
    private let createAccountButton: AnyView

    public init(
        viewModel: AccountScreenViewModel,
        loginButton: AnyView,
        createAccountButton: AnyView
    ) {
        self.viewModel = viewModel
        self.loginButton = loginButton
        self.createAccountButton = createAccountButton
    }

    public var body: some View {
        Form {
            Section("Account") {
                if let user = viewModel.currentUser {
                    LabeledContent("Name", value: "\(user.firstName) \(user.lastName)")
                    LabeledContent("Email", value: user.email)
                    Button("Log Out", role: .destructive) {
                        Task { await viewModel.didTapLogOut() }
                    }
                } else {
                    Text("You're browsing as a guest.")
                        .foregroundStyle(.secondary)
                    loginButton
                    createAccountButton
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
