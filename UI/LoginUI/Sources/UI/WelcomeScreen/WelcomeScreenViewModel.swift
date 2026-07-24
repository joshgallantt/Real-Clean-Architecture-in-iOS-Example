import Foundation

@MainActor
public final class WelcomeScreenViewModel: ObservableObject {
    @Published var isPresentingLogin = false

    private let onContinueAsGuest: () -> Void

    public init(onContinueAsGuest: @escaping () -> Void) {
        self.onContinueAsGuest = onContinueAsGuest
    }

    func didTapLogIn() {
        isPresentingLogin = true
    }

    func didContinueAsGuest() {
        onContinueAsGuest()
    }
}
