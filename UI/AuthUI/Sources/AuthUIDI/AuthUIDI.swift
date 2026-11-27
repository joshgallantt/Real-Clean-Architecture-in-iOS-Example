import SwiftUI
import Session
import SheetUI
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: builds this feature's view
/// hierarchy and holds its collaborators.
///
/// Martin, Ch. 10 — Interface Segregation Principle: handed individual use cases, never a whole
/// component container. Injecting the container would be a Service Locator (Fowler, *Inversion of
/// Control Containers and the Dependency Injection Pattern* (2004)) and would blur the boundary the
/// layering exists to enforce.
public struct AuthUIDI {
    public let presenter: AuthPresenter
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase

    @MainActor
    public init(
        loginUseCase: LoginUseCase,
        createAccountUseCase: CreateAccountUseCase,
        getSessionUseCase: GetSessionUseCase,
        sheetPresenting: SheetPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementView: TrackElementViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        trackEvent: TrackEventUseCase
    ) {
        self.presenter = AuthPresenter(
            sheetPresenting: sheetPresenting,
            loginUseCase: loginUseCase,
            createAccountUseCase: createAccountUseCase,
            getSession: getSessionUseCase,
            trackScreenView: trackScreenView,
            trackElementView: trackElementView,
            trackElementInteraction: trackElementInteraction,
            trackEvent: trackEvent
        )
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    /// Drawn on another feature's screen, which the environment says — not this container, and not
    /// the caller.
    @MainActor
    public func loginButtonView(title: String, onAuthenticated: @escaping () -> Void) -> some View {
        AuthEntryButton(
            viewModel: AuthEntryButtonViewModel(
                element: AuthTrackingPlan.logIn,
                authenticate: { [presenter] in await presenter.logIn() },
                trackElementInteraction: trackElementInteraction,
                onAuthenticated: onAuthenticated
            ),
            title: title
        )
    }

    /// The first screen of all, so it declares its own name — nothing above it is a screen.
    @MainActor
    public func welcomeView(
        onContinueAsGuest: @escaping () -> Void,
        onAuthenticated: @escaping () -> Void
    ) -> some View {
        WelcomeScreenView(
            viewModel: WelcomeScreenViewModel(
                presenter: presenter,
                trackScreenView: trackScreenView,
                trackElementInteraction: trackElementInteraction,
                onContinueAsGuest: onContinueAsGuest,
                onAuthenticated: onAuthenticated
            )
        )
        .trackingScreen(AuthTrackingPlan.welcome)
    }
}
