import SwiftUI

struct LoginSheetView: View {
    @StateObject private var viewModel: LoginSheetViewModel

    init(viewModel: @autoclosure @escaping () -> LoginSheetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            if let greeting = viewModel.successGreeting {
                AuthSuccessView(title: "Login Successful", message: greeting)
                    .transition(.opacity)
            } else {
                form
                    .transition(.opacity)
            }
        }
        .padding(24)
        .animation(.easeInOut(duration: 0.25), value: viewModel.successGreeting)
        .authSheetPresentation(height: 460)
    }

    private var form: some View {
        VStack(spacing: 28) {
            AuthSheetHeader(
                icon: "bag.fill",
                title: "Welcome Back",
                subtitle: "Log in to sync your bag and wishlist."
            )

            VStack(spacing: 12) {
                AuthField(icon: "envelope.fill") {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                AuthField(icon: "lock.fill") {
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
                if let error = viewModel.error {
                    AuthErrorBanner(message: error)
                }
            }

            AuthPrimaryButton(title: "Log In", isLoading: viewModel.isLoading) {
                Task { await viewModel.logIn() }
            }
        }
    }
}
