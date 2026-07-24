import SwiftUI
import AccountUI
import Session

public struct AccountUIDI {
    private let navigation: AccountNavigation
    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase

    public init(
        navigation: AccountNavigation,
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase
    ) {
        self.navigation = navigation
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
    }

    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase,
                navigation: navigation
            )
        )
    }
}
