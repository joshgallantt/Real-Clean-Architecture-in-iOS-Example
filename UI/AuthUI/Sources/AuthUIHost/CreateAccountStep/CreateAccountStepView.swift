import SwiftUI

struct CreateAccountSheetView: View {
    @StateObject private var viewModel: CreateAccountSheetViewModel

    init(viewModel: @autoclosure @escaping () -> CreateAccountSheetViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            if let greeting = viewModel.successGreeting {
                AuthSuccessView(title: "Account Created", message: greeting)
                    .transition(.opacity)
            } else {
                form
                    .transition(.opacity)
            }
        }
        .padding(24)
        .animation(.easeInOut(duration: 0.25), value: viewModel.successGreeting)
        .authSheetPresentation(height: 580)
    }

    private var form: some View {
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
    }
}
