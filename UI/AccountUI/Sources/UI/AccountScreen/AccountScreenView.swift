import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let loginView: () -> AnyView

    public init(
        viewModel: AccountScreenViewModel,
        loginView: @escaping () -> AnyView
    ) {
        self.viewModel = viewModel
        self.loginView = loginView
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
                    Button("Log In") {
                        viewModel.didTapLogIn()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $viewModel.isPresentingLogin) {
            loginView()
        }
    }
}
