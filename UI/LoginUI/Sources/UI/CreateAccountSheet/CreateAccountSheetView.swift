import SwiftUI

public struct CreateAccountSheetView: View {
    @StateObject private var viewModel: CreateAccountSheetViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: @autoclosure @escaping () -> CreateAccountSheetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 24) {
                AuthSheetHeader(
                    icon: "bag.fill",
                    title: "Create Account",
                    subtitle: "Join to save your bag and wishlist across devices."
                )

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        AuthField(icon: "person.fill") {
                            TextField("First name", text: $viewModel.firstName)
                                .textContentType(.givenName)
                        }
                        AuthField(icon: "person.fill") {
                            TextField("Last name", text: $viewModel.lastName)
                                .textContentType(.familyName)
                        }
                    }
                    AuthField(icon: "envelope.fill") {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    AuthField(icon: "lock.fill") {
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.newPassword)
                    }
                    if let error = viewModel.error {
                        AuthErrorBanner(message: error)
                    }
                }

                AuthPrimaryButton(title: "Create Account", isLoading: viewModel.isLoading) {
                    Task { await viewModel.createAccount() }
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
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
