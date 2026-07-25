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
        VStack(spacing: 28) {
            AuthSheetHeader(
                icon: "lock.shield.fill",
                title: "Account Required",
                subtitle: message
            )

            AuthActionButtons(onSelectLogIn: onSelectLogIn, onSelectCreateAccount: onSelectCreateAccount)
        }
        .padding(24)
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}
