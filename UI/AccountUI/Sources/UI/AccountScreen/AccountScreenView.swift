import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel

    public init(viewModel: AccountScreenViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Account") {
                if let user = viewModel.currentUser {
                    LabeledContent("Name", value: "\(user.firstName) \(user.lastName)")
                    LabeledContent("Username", value: user.username)
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
    }
}
