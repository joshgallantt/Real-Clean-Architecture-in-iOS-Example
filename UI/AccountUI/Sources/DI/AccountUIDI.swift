import SwiftUI
import AccountUI
import Session
import AuthGate

public struct AccountUIDI {
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let authGate: AuthGate

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        authGate: AuthGate
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.authGate = authGate
    }

    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase
            ),
            authGate: authGate
        )
    }
}
