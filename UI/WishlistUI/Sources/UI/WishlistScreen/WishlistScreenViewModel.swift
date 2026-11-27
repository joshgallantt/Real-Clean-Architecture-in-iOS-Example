import Combine
import Foundation
import AuthUI
import Session
import Settings
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing.
///
/// Martin, Ch. 7 — Single Responsibility Principle: what the tab itself decides — whether there is
/// anybody to show a list to, and whether the stock alerts are one of the things shown. The lists
/// are not here: the faves are `SavedProductsViewModel`'s and the stock alerts belong to their own
/// feature, so this holds only what is about the tab rather than about any list on it.
public final class WishlistScreenViewModel {
    private(set) var isAuthenticated = false

    /// Whether the stock alerts section is drawn above the faves. A shopper switches it in
    /// Settings; the alerts themselves are untouched either way, and their own screen still opens.
    private(set) var showsStockAlerts = true

    private let observeSession: ObserveSessionUseCase
    private let observeSetting: ObserveSettingUseCase
    private let authPresenter: AuthPresenting
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private var cancellables = Set<AnyCancellable>()

    public init(
        observeSession: ObserveSessionUseCase,
        observeSetting: ObserveSettingUseCase,
        authPresenter: AuthPresenting,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.observeSession = observeSession
        self.observeSetting = observeSetting
        self.authPresenter = authPresenter
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    /// The work the last interaction started, so a test can wait for exactly that.
    @ObservationIgnored public private(set) var inFlight: Task<Void, Never>?

    /// The tab is one screen whichever of its lists the shopper looks at, so the visit is reported
    /// here, once, and not by the lists on it.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    /// View All opens the faves' own screen; what it is about is that list.
    func didTapViewAllFaves(in context: TrackingContext) {
        trackElementInteraction(WishlistTrackingPlan.viewAll, about: WishlistTrackingPlan.item(WishlistTrackingPlan.faves), in: context)
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

        observeSetting(.favoritesStockAlertsSection)
            .sink { [weak self] isOn in
                self?.showsStockAlerts = isOn
            }
            .store(in: &cancellables)
    }
}
