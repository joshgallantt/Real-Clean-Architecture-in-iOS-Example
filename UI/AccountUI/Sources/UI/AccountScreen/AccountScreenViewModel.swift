import Combine
import Foundation
import Session
import Tracking

@MainActor
@Observable
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the capabilities it calls, not
/// a container that could resolve anything.
public final class AccountScreenViewModel {
    private(set) var session: Session = .guest

    private let getSession: GetSessionUseCase
    private let observeSession: ObserveSessionUseCase
    private let logoutUseCase: LogoutUseCase
    private let navigation: any AccountNavigation
    private let trackScreenView: TrackScreenViewUseCase
    private let trackElementInteraction: TrackElementInteractionUseCase
    private var cancellables = Set<AnyCancellable>()

    var currentUser: User? { session.user }

    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        logoutUseCase: LogoutUseCase,
        navigation: any AccountNavigation,
        trackScreenView: TrackScreenViewUseCase,
        trackElementInteraction: TrackElementInteractionUseCase
    ) {
        self.getSession = getSession
        self.observeSession = observeSession
        self.logoutUseCase = logoutUseCase
        self.navigation = navigation
        self.trackScreenView = trackScreenView
        self.trackElementInteraction = trackElementInteraction
    }

    func onAppear() {
        session = getSession()

        guard cancellables.isEmpty else { return }
        observeSession()
            .sink { [weak self] session in
                self?.session = session
            }
            .store(in: &cancellables)
    }

    /// Every time the tab comes into view, which is every time the shopper switches to it — not only
    /// the first, which is all `onAppear`'s subscription guard is about.
    func didAppear(in context: TrackingContext) {
        trackScreenView(context.screen)
    }

    func didTapLogOut(in context: TrackingContext) async {
        trackElementInteraction(AccountTrackingPlan.logOut, in: context)
        await logoutUseCase()
    }

    /// The rows go where they go from here rather than from the view, so a tap is one thing that
    /// both navigates and is counted — and a test can say both happened.
    func didTapOrders(in context: TrackingContext) {
        trackElementInteraction(AccountTrackingPlan.orders, in: context)
        navigation.openOrderHistory()
    }

    func didTapSettings(in context: TrackingContext) {
        trackElementInteraction(AccountTrackingPlan.settings, in: context)
        navigation.openSettings()
    }
}
