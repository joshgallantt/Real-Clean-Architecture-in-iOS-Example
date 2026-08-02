import SwiftUI
import AccountUI
import Session
import AuthUIDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct AccountUIDI {
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let authUIDI: AuthUIDI
    private let ordersRow: AnyView
    private let settingsRow: AnyView

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        authUIDI: AuthUIDI,
        ordersRow: AnyView,
        settingsRow: AnyView
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.authUIDI = authUIDI
        self.ordersRow = ordersRow
        self.settingsRow = settingsRow
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
            ),
            ordersRow: ordersRow,
            settingsRow: settingsRow
        )
    }
}
