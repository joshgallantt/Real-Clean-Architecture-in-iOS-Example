import SwiftUI
import AccountUI
import Session
import AuthUIDI
import Tracking
import TrackingUI

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
    private let navigation: any AccountNavigation
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        authUIDI: AuthUIDI,
        navigation: any AccountNavigation,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.authUIDI = authUIDI
        self.navigation = navigation
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    /// The tab declares its screen here, above the screen itself, so everything drawn on it — the
    /// Log In button that belongs to AuthUI included — reports it without being told.
    @MainActor
    public func mainView() -> some View {
        AccountScreenView(
            viewModel: AccountScreenViewModel(
                getSession: getSession,
                observeSession: observeSession,
                logoutUseCase: logoutUseCase,
                navigation: navigation,
                trackScreenView: trackScreenView,
                trackElementInteraction: trackElementInteraction
            ),
            loginButton: AnyView(
                authUIDI.loginButtonView(title: "Log In", onAuthenticated: {})
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            )
        )
        .trackingScreen(AccountTrackingPlan.screen)
    }
}
