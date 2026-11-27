import Combine
import Foundation
import AuthUI
import Session
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 7 — Single Responsibility Principle: whether there is anybody to show a list to. It
/// used to hold the list as well, which meant a second list on the tab would have made it hold two
/// — so the lists moved to `SavedProductsViewModel`, one instance each, and this kept the one thing
/// that is about the tab rather than about either list.
public final class WishlistScreenViewModel {
    private(set) var isAuthenticated = false

    private let observeSession: ObserveSessionUseCase
    private let authPresenter: AuthPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(
        observeSession: ObserveSessionUseCase,
        authPresenter: AuthPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.observeSession = observeSession
        self.authPresenter = authPresenter
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    /// The work the last interaction started, so a test can wait for exactly that.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?

    /// The tab is one screen whichever of its three lists the shopper looks at, so the visit is
    /// reported here, once, and not by the lists on it.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    /// View All opens a list's own screen; what it is about is which list.
    func didTapViewAll(_ list: TrackingContext.List, in context: TrackingContext) {
        trackElementInteraction(WishlistTrackingPlan.viewAll, about: WishlistTrackingPlan.item(list), in: context)
    }

    /// The sheet covers the tab, and closing it does not make the tab appear again — so the tab is
    /// reported again here, by the one thing that knows a sheet was in the way.
    func didTapSignIn(in context: TrackingContext) {
        trackElementInteraction(WishlistTrackingPlan.signIn, in: context)
        inFlight = Task {
            await authPresenter.show(AuthenticationPrompt(
                title: "Keep Your Faves",
                message: "Sign in and everything you save sticks around.",
                icon: "heart.fill"
            ))
            trackScreenView(context.screen)
        }
    }

    func onAppear() {
        guard cancellables.isEmpty else { return }

        observeSession()
            .sink { [weak self] session in
                self?.isAuthenticated = session.isLoggedIn
            }
            .store(in: &cancellables)
    }
}
