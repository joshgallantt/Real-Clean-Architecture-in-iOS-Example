import SwiftUI

struct AuthActionButtons: View {
    let onSelectLogIn: () -> Void
    let onSelectCreateAccount: () -> Void

    var body: some View {
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
