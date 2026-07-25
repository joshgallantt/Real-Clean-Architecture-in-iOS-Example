import SwiftUI

struct LoginSheetView: View {
    @StateObject private var viewModel: LoginSheetViewModel

    init(viewModel: @autoclosure @escaping () -> LoginSheetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            .padding(24)

            AuthSheetCloseButton()
        }
        .authSheetPresentation(height: 460)
    }
}
