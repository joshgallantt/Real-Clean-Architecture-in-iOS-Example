import SwiftUI
import Tracking
import TrackingUI

public struct AccountScreenView: View {
    @Environment(\.trackingContext) private var trackingContext
    let viewModel: AccountScreenViewModel
    /// `loginButton` stays an `AnyView` because it is a cross-cutting port — another package's
    /// whole button, presented here. The rows this screen draws and owns go through the view model,
    /// which knows where they lead.
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
                    LabeledContent("Name", value: user.name.full)
                    LabeledContent("Email", value: user.email.value)
                    Button("Log Out", role: .destructive) {
                        Task { await viewModel.didTapLogOut(in: trackingContext) }
                    }
                } else {
                    Text("You're just looking right now.")
                        .foregroundStyle(.secondary)
                    loginButton
                }
            }

            Section("Orders") {
                Button { viewModel.didTapOrders(in: trackingContext) } label: {
                    Label("Your Orders", systemImage: "shippingbox")
                }
                .foregroundStyle(.primary)
            }

            Section("Settings") {
                Button { viewModel.didTapSettings(in: trackingContext) } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .foregroundStyle(.primary)
            }
        }
        .onAppear { viewModel.onAppear() }
        .onScreenAppear { viewModel.didAppear(in: $0) }
    }
}
