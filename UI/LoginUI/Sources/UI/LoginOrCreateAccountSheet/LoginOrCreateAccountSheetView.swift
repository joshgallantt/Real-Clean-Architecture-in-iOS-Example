import SwiftUI

public struct LoginOrCreateAccountSheetView: View {
    private let message: String
    private let onSelectLogIn: () -> Void
    private let onSelectCreateAccount: () -> Void

    public init(
        message: String,
        onSelectLogIn: @escaping () -> Void,
        onSelectCreateAccount: @escaping () -> Void
    ) {
        self.message = message
        self.onSelectLogIn = onSelectLogIn
        self.onSelectCreateAccount = onSelectCreateAccount
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)

            Button(action: onSelectLogIn) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onSelectCreateAccount) {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}
