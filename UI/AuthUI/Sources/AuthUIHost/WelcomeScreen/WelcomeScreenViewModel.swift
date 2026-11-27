import Foundation
import Tracking

@MainActor
@Observable
public final class WelcomeScreenViewModel {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action synchronously, so anything that has to be
    /// awaited starts a `Task` and returns. Keeping the handle is what lets a
    /// test wait for that work rather than guess at how long it takes.
    ///
    /// `@ObservationIgnored` because no view body reads it: it exists for the
    /// caller that started the work, not for anything drawn from it.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?
    private let presenter: AuthPresenter
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private let onContinueAsGuest: () -> Void
    private let onAuthenticated: () -> Void

    public init(
        presenter: AuthPresenter,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase,
        onContinueAsGuest: @escaping () -> Void,
        onAuthenticated: @escaping () -> Void
    ) {
        self.presenter = presenter
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
        self.onContinueAsGuest = onContinueAsGuest
        self.onAuthenticated = onAuthenticated
    }

    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func didContinueAsGuest(in context: TrackingContext) {
        trackElementInteraction(AuthTrackingPlan.continueAsGuest, in: context)
        onContinueAsGuest()
    }

    func didTapLogIn(in context: TrackingContext) {
        trackElementInteraction(AuthTrackingPlan.logIn, in: context)
        inFlight = Task {
            if await presenter.logIn() { onAuthenticated() }
        }
    }

    func didTapCreateAccount(in context: TrackingContext) {
        trackElementInteraction(AuthTrackingPlan.createAccount, in: context)
        inFlight = Task {
            if await presenter.createAccount() { onAuthenticated() }
        }
    }

}
