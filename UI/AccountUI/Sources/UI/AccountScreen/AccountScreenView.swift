import SwiftUI

public struct AccountScreenView: View {
    @ObservedObject var viewModel: AccountScreenViewModel
    private let loginButton: AnyView

    /// Where the rows go. `loginButton` stays an `AnyView` because it is a
    /// cross-cutting port — another package's whole button, presented here.
    /// A row that this screen draws and this screen owns is a different thing,
    /// and it asks for a destination rather than being handed one.
    private let navigation: any AccountNavigation

    public init(
        viewModel: AccountScreenViewModel,
        loginButton: AnyView,
        navigation: any AccountNavigation
    ) {
        self.viewModel = viewModel
        self.loginButton = loginButton
        self.navigation = navigation
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
                    Text("You're just looking right now.")
                        .foregroundStyle(.secondary)
                    loginButton
                }
            }

            Section("Orders") {
                Button { navigation.openOrderHistory() } label: {
                    Label("Your Orders", systemImage: "shippingbox")
                }
                .foregroundStyle(.primary)
            }

            Section("Settings") {
                Button { navigation.openSettings() } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .foregroundStyle(.primary)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
