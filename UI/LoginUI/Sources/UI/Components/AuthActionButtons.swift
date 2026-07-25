import SwiftUI

/// The shared Log In / Create Account button pair. Drop this into any bespoke gate
/// sheet to get consistent styling and behavior without depending on LoginOrCreateAccountSheetView's layout.
public struct AuthActionButtons: View {
    private let onSelectLogIn: () -> Void
    private let onSelectCreateAccount: () -> Void

    public init(onSelectLogIn: @escaping () -> Void, onSelectCreateAccount: @escaping () -> Void) {
        self.onSelectLogIn = onSelectLogIn
        self.onSelectCreateAccount = onSelectCreateAccount
    }

    public var body: some View {
        VStack(spacing: 12) {
            Button(action: onSelectLogIn) {
                Text("Log In")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onSelectCreateAccount) {
                Text("Create Account")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
}
