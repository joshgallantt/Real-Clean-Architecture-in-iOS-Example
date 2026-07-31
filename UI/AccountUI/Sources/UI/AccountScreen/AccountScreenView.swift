import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let loginButton: AnyView

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: a row that
    /// goes somewhere this package cannot name, arriving already built the way `loginButton` does.
    /// `AccountUI` never learns there is an order domain or what the route to it is called.
    private let ordersRow: AnyView

    public init(
        viewModel: AccountScreenViewModel,
        loginButton: AnyView,
        ordersRow: AnyView
    ) {
        self.viewModel = viewModel
        self.loginButton = loginButton
        self.ordersRow = ordersRow
    }

    public var body: some View {
        Form {
            Section("Account") {
                if let user = viewModel.currentUser {
                    LabeledContent("Name", value: user.name.full)
                    LabeledContent("Email", value: user.email.value)
                    Button("Log Out", role: .destructive) {
                        Task { await viewModel.didTapLogOut() }
                    }
                } else {
                    Text("You're browsing as a guest.")
                        .foregroundStyle(.secondary)
                    loginButton
                }
            }

            Section("Orders") {
                ordersRow
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
