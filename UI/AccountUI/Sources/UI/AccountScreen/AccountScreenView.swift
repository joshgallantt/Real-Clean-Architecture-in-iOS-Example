import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    @State private var isPresentingLogin = false
    @State private var isPresentingCreateAccount = false
    private let loginView: (@escaping () -> Void) -> AnyView
    private let createAccountView: (@escaping () -> Void) -> AnyView

    public init(
        viewModel: AccountScreenViewModel,
        loginView: @escaping (@escaping () -> Void) -> AnyView,
        createAccountView: @escaping (@escaping () -> Void) -> AnyView
    ) {
        self.viewModel = viewModel
        self.loginView = loginView
        self.createAccountView = createAccountView
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
                        isPresentingLogin = true
                    }
                    Button("Create Account") {
                        isPresentingCreateAccount = true
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $isPresentingLogin) {
            loginView { isPresentingLogin = false }
        }
        .sheet(isPresented: $isPresentingCreateAccount) {
            createAccountView { isPresentingCreateAccount = false }
        }
    }
}
