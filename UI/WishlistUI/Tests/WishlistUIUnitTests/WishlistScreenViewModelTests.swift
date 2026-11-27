import AuthUITestSupport
import Foundation
import SessionTestSupport
import SettingsTestSupport
import Testing
import Tracking
import TrackingTestSupport
import Session
import Settings
@testable import WishlistUI
@testable import WishlistUITestSupport

@MainActor
@Suite("The wishlist tab")
struct WishlistScreenViewModelTests {
    @Test("A guest is not shown as signed in")
    func guestIsNotAuthenticated() {
        let viewModel = WishlistScreenViewModel(
            observeSession: SpyObserveSessionUseCase(),
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )

        viewModel.onAppear()

        #expect(viewModel.isAuthenticated == false)
    }

    @Test("Someone already signed in when the tab appears is shown as signed in")
    func alreadySignedInIsAuthenticated() {
        let viewModel = WishlistScreenViewModel(
            observeSession: SpyObserveSessionUseCase(initial: .authenticated(.fixture())),
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )

        viewModel.onAppear()

        #expect(viewModel.isAuthenticated)
    }

    @Test("Signing in after arriving is picked up too")
    func signingInLaterIsPickedUp() {
        let observeSession = SpyObserveSessionUseCase()
        let viewModel = WishlistScreenViewModel(
            observeSession: observeSession,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )
        viewModel.onAppear()

        observeSession.send(.authenticated(.fixture()))

        #expect(viewModel.isAuthenticated)
    }

    @Test("Signing out after arriving is picked up too")
    func signingOutLaterIsPickedUp() {
        let observeSession = SpyObserveSessionUseCase(initial: .authenticated(.fixture()))
        let viewModel = WishlistScreenViewModel(
            observeSession: observeSession,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )
        viewModel.onAppear()

        observeSession.send(.guest)

        #expect(viewModel.isAuthenticated == false)
    }

    @Test("Appearing subscribes to session changes only once, however often it happens")
    func subscribesOnce() {
        let observeSession = SpyObserveSessionUseCase()
        let viewModel = WishlistScreenViewModel(
            observeSession: observeSession,
            observeSetting: StubObserveSettingUseCase(turnedOff: []),
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )

        viewModel.onAppear()
        viewModel.onAppear()
        viewModel.onAppear()

        #expect(observeSession.callCount == 1)
    }

    // MARK: - The stock alerts section

    private func makeViewModel(settings: StubObserveSettingUseCase) -> WishlistScreenViewModel {
        WishlistScreenViewModel(
            observeSession: SpyObserveSessionUseCase(initial: .authenticated(.fixture())),
            observeSetting: settings,
            authPresenter: SpyAuthPresenting(),
            trackScreenView: SpyTrackScreenViewUseCase(),
            trackElementInteraction: SpyTrackElementInteractionUseCase()
        )
    }

    @Test("The stock alerts section is shown to a shopper who has not switched it off")
    func stockAlertsAreShownUntilSwitchedOff() {
        let viewModel = makeViewModel(settings: StubObserveSettingUseCase(turnedOff: []))

        viewModel.onAppear()

        #expect(viewModel.showsStockAlerts)
    }

    @Test("A shopper who switched the stock alerts section off is not shown it")
    func stockAlertsSwitchedOff() {
        let viewModel = makeViewModel(settings: StubObserveSettingUseCase(turnedOff: [.favoritesStockAlertsSection]))

        viewModel.onAppear()

        #expect(viewModel.showsStockAlerts == false)
    }

    @Test("Switching the section off or on in Settings is picked up without leaving the tab")
    func switchingIsPickedUp() {
        let settings = StubObserveSettingUseCase(turnedOff: [])
        let viewModel = makeViewModel(settings: settings)
        viewModel.onAppear()

        settings.turn(.favoritesStockAlertsSection, on: false)
        #expect(viewModel.showsStockAlerts == false)

        settings.turn(.favoritesStockAlertsSection, on: true)
        #expect(viewModel.showsStockAlerts)
    }

    @Test("Switching off what changed in the bag leaves the stock alerts shown")
    func theBagSettingIsNotThisOne() {
        let viewModel = makeViewModel(settings: StubObserveSettingUseCase(turnedOff: [.bagChangesSection]))

        viewModel.onAppear()

        #expect(viewModel.showsStockAlerts)
    }
}
