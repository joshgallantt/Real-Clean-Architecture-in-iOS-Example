import SwiftUI
import AccountUI
import Session
import AuthUIDI

public struct AccountUIDI {
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let authUIDI: AuthUIDI

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        authUIDI: AuthUIDI
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.authUIDI = authUIDI
    }

    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase
            ),
            loginButton: AnyView(
                authUIDI.loginButtonView()
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            )
        )
    }
}
