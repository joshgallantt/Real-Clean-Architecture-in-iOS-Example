import SwiftUI
import AuthUI

struct AuthenticationChooserSheetView: View {
    let prompt: AuthenticationPrompt
    let onSelectLogIn: () -> Void
    let onSelectCreateAccount: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            AuthSheetHeader(
                icon: prompt.icon,
                title: prompt.title,
                subtitle: prompt.message
            )

            AuthActionButtons(
                onSelectLogIn: onSelectLogIn,
                onSelectCreateAccount: onSelectCreateAccount
            )
        }
        .padding(24)
        .authSheetPresentation(height: 380)
    }
}
