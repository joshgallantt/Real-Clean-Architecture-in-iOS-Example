import SwiftUI

struct CreateAccountStepView: View {
    @ObservedObject var viewModel: CreateAccountStepViewModel
    let header: AuthHeader
    let onShowPeer: () -> Void

    @FocusState private var focused: Field?

    private enum Field {
        case firstName, lastName, email, password
    }

    var body: some View {
        AuthFormScaffold {
            VStack(spacing: 24) {
                AuthSheetHeader(header)

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        AuthField(icon: "person.fill") {
                            TextField("First name", text: $viewModel.firstName)
                                .textContentType(.givenName)
                                .submitLabel(.next)
                                .focused($focused, equals: .firstName)
                                .onSubmit { focused = .lastName }
                        }
                        AuthField(icon: "person.fill") {
                            TextField("Last name", text: $viewModel.lastName)
                                .textContentType(.familyName)
                                .submitLabel(.next)
                                .focused($focused, equals: .lastName)
                                .onSubmit { focused = .email }
                        }
                    }
                    AuthField(icon: "envelope.fill") {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.next)
                            .focused($focused, equals: .email)
                            .onSubmit { focused = .password }
                    }
                    AuthField(icon: "lock.fill") {
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(.newPassword)
                            .submitLabel(.go)
                            .focused($focused, equals: .password)
                            .onSubmit(submit)
                    }
                    if let error = viewModel.error {
                        AuthErrorBanner(message: error)
                    }
                }

                AuthPrimaryButton(
                    title: "Create Account",
                    isEnabled: viewModel.canSubmit,
                    isLoading: viewModel.isLoading,
                    action: submit
                )

                AuthSecondaryLink(title: AuthenticationStep.createAccount.peerLinkTitle, action: onShowPeer)
            }
        }
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        focused = nil
        Task { await viewModel.createAccount() }
    }
}
