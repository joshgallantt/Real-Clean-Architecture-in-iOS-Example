import SwiftUI

public struct WelcomeScreenView: View {
    @StateObject private var viewModel: WelcomeScreenViewModel
    private let loginButton: AnyView
    private let createAccountButton: AnyView

    public init(
        viewModel: @autoclosure @escaping () -> WelcomeScreenViewModel,
        loginButton: AnyView,
        createAccountButton: AnyView
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.loginButton = loginButton
        self.createAccountButton = createAccountButton
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bag.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.largeTitle.bold())
                Text("Sign in to sync your bag and wishlist, or keep browsing as a guest.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                loginButton
                createAccountButton

                Button {
                    viewModel.didContinueAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}
