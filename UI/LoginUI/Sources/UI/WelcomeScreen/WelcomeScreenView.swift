import SwiftUI

public struct WelcomeScreenView: View {
    @ObservedObject var viewModel: WelcomeScreenViewModel
    private let loginView: () -> AnyView

    public init(
        viewModel: WelcomeScreenViewModel,
        loginView: @escaping () -> AnyView
    ) {
        self.viewModel = viewModel
        self.loginView = loginView
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

            VStack(spacing: 12) {
                Button {
                    viewModel.didTapLogIn()
                } label: {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    viewModel.didContinueAsGuest()
                } label: {
                    Text("Continue as Guest")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .sheet(isPresented: $viewModel.isPresentingLogin) {
            loginView()
        }
    }
}
