import SwiftUI
import AccountUI
import Session

public struct AccountUIDI {
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let loginView: (@escaping () -> Void) -> AnyView
    private let createAccountView: (@escaping () -> Void) -> AnyView

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        loginView: @escaping (@escaping () -> Void) -> AnyView,
        createAccountView: @escaping (@escaping () -> Void) -> AnyView
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.loginView = loginView
        self.createAccountView = createAccountView
    }

    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase
            ),
            loginView: loginView,
            createAccountView: createAccountView
        )
    }
}
