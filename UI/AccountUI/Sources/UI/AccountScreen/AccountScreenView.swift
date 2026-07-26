import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let loginButton: AnyView

    public init(
        viewModel: AccountScreenViewModel,
        loginButton: AnyView
    ) {
        self.viewModel = viewModel
        self.loginButton = loginButton
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
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
