import Foundation

@MainActor
public final class WelcomeScreenViewModel: ObservableObject {
    private let presenter: AuthPresenter
    private let onContinueAsGuest: () -> Void
    private let onAuthenticated: () -> Void

    public init(
        presenter: AuthPresenter,
        onContinueAsGuest: @escaping () -> Void,
        onAuthenticated: @escaping () -> Void
    ) {
        self.presenter = presenter
        self.onContinueAsGuest = onContinueAsGuest
        self.onAuthenticated = onAuthenticated
    }

    func didContinueAsGuest() {
        onContinueAsGuest()
    }

    func didTapLogIn() {
        Task {
            if await presenter.logIn() { onAuthenticated() }
        }
    }

    func didTapCreateAccount() {
        Task {
            if await presenter.createAccount() { onAuthenticated() }
        }
    }
}
