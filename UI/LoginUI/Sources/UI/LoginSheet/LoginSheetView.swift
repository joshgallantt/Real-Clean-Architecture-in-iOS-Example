import SwiftUI

public struct LoginSheetView: View {
    @StateObject private var viewModel: LoginSheetViewModel
    @Environment(\.dismiss) private var dismiss

    public init(
        viewModel: @autoclosure @escaping () -> LoginSheetViewModel
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
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
                    Task { await viewModel.login() }
                }
            }
            .padding(24)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary, Color(.tertiarySystemFill))
            }
            .padding(16)
        }
        .presentationDetents([.height(460)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
