import SwiftUI
import AuthGate

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let authGate: AuthGate

    public init(
        viewModel: AccountScreenViewModel,
        authGate: AuthGate
    ) {
        self.viewModel = viewModel
        self.authGate = authGate
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
                        authGate.requireAuthentication {}
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
