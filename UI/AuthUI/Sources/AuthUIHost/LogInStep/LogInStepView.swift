import SwiftUI

struct LogInStepView: View {
    @ObservedObject var viewModel: LogInStepViewModel
    let header: AuthHeader
    let onShowPeer: () -> Void

    @FocusState private var focused: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        AuthFormScaffold {
            VStack(spacing: 24) {
                AuthSheetHeader(header)

                VStack(spacing: 12) {
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
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focused, equals: .password)
                            .onSubmit(submit)
                    }
                    if let error = viewModel.error {
                        AuthErrorBanner(message: error)
                    }
                }

                AuthPrimaryButton(
                    title: "Log In",
                    isEnabled: viewModel.canSubmit,
                    isLoading: viewModel.isLoading,
                    action: submit
                )

                AuthSecondaryLink(title: AuthenticationStep.logIn.peerLinkTitle, action: onShowPeer)
            }
        }
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        focused = nil
        Task { await viewModel.logIn() }
    }
}
