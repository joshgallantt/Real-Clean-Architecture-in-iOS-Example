import SwiftUI

public struct WelcomeScreenView: View {
    @StateObject private var viewModel: WelcomeScreenViewModel

    public init(viewModel: @autoclosure @escaping () -> WelcomeScreenViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        VStack(spacing: 24) {

            Image(systemName: "bag.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("Hey")
                    .font(.largeTitle.bold())
                Text("Sign in to keep your bag and your faves. Or just have a look around.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }


            VStack(spacing: 16) {
                Button {
                    viewModel.didTapLogIn()
                } label: {
                    Text("Sign In").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    viewModel.didTapCreateAccount()
                } label: {
                    Text("Create Account").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    viewModel.didContinueAsGuest()
                } label: {
                    Text("Just Looking")
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
