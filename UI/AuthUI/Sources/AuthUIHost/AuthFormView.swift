import SwiftUI

struct AuthFormView: View {
    @ObservedObject var viewModel: AuthViewModel

    @FocusState private var focused: Field?

    private enum Field {
        case firstName, lastName, email, password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                VStack(spacing: 10) {
                    if viewModel.mode == .createAccount {
                        HStack(spacing: 10) {
                            field(icon: "person.fill") {
                                TextField("First name", text: $viewModel.firstName)
                                    .textContentType(.givenName)
                                    .submitLabel(.next)
                                    .focused($focused, equals: .firstName)
                                    .onSubmit { focused = .lastName }
                            }
                            field(icon: "person.fill") {
                                TextField("Last name", text: $viewModel.lastName)
                                    .textContentType(.familyName)
                                    .submitLabel(.next)
                                    .focused($focused, equals: .lastName)
                                    .onSubmit { focused = .email }
                            }
                        }
                    }
                    field(icon: "envelope.fill") {
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.next)
                            .focused($focused, equals: .email)
                            .onSubmit { focused = .password }
                    }
                    field(icon: "lock.fill") {
                        SecureField("Password", text: $viewModel.password)
                            .textContentType(viewModel.mode == .logIn ? .password : .newPassword)
                            .submitLabel(.go)
                            .focused($focused, equals: .password)
                            .onSubmit(submit)
                    }
                    if let error = viewModel.error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                submitButton

                Button {
                    viewModel.switchToPeerMode()
                } label: {
                    Text(viewModel.mode.peerLinkTitle)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { focused = nil }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: viewModel.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.tint)
            }
            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(.title3.bold())
                Text(viewModel.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            ZStack {
                Text(viewModel.mode.submitTitle)
                    .fontWeight(.semibold)
                    .opacity(viewModel.isLoading ? 0 : 1)
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isLoading ? Color(.systemGray3) : .accentColor)
        .controlSize(.large)
        .disabled(viewModel.isLoading || !viewModel.canSubmit)
    }

    @ViewBuilder
    private func field<Content: View>(icon: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            content()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func submit() {
        guard viewModel.canSubmit else { return }
        focused = nil
        Task { await viewModel.submit() }
    }
}
