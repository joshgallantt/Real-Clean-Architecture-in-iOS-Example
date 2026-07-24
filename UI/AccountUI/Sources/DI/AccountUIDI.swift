import SwiftUI
import AccountUI
import Session

public struct AccountUIDI {
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let makeLoginView: () -> AnyView

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        makeLoginView: @escaping () -> AnyView
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.makeLoginView = makeLoginView
    }

    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase
            ),
            loginView: makeLoginView
        )
    }
}
