import Foundation

@MainActor
public final class WelcomeScreenViewModel: ObservableObject {
    @Published var isPresentingLogin = false
    @Published var isPresentingCreateAccount = false

    private let onContinueAsGuest: () -> Void

    public init(onContinueAsGuest: @escaping () -> Void) {
        self.onContinueAsGuest = onContinueAsGuest
    }

    func didTapLogIn() {
        isPresentingLogin = true
    }

    func didTapCreateAccount() {
        isPresentingCreateAccount = true
    }

    func didContinueAsGuest() {
        onContinueAsGuest()
    }
}
