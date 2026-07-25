import Foundation

@MainActor
public final class WelcomeScreenViewModel: ObservableObject {
    private let onContinueAsGuest: () -> Void

    public init(onContinueAsGuest: @escaping () -> Void) {
        self.onContinueAsGuest = onContinueAsGuest
    }

    func didContinueAsGuest() {
        onContinueAsGuest()
    }
}
