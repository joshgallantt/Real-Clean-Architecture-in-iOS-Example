import Foundation
import ProductTestSupport
import SessionTestSupport
import Testing
import Session
import Tracking
import TrackingTestSupport
@testable import AccountUI
@testable import AccountUITestSupport

@MainActor
@Suite("What the account screen tells the shop")
struct TrackingTheAccountScreenTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()
    private let navigation = SpyAccountNavigation()

    private func makeViewModel() -> AccountScreenViewModel {
        AccountScreenViewModel(
            getSession: StubGetSessionUseCase(),
            observeSession: SpyObserveSessionUseCase(),
            logoutUseCase: SpyLogoutUseCase(),
            navigation: navigation,
            trackScreenView: screens,
            trackElementInteraction: taps
        )
    }

    @Test("Every time the tab comes into view it is a view of the account screen")
    func everyAppearanceIsAView() {
        let viewModel = makeViewModel()

        viewModel.didAppear(in: .screen("account"))
        viewModel.didAppear(in: .screen("account"))

        #expect(screens.events == [.screenViewed("account"), .screenViewed("account")])
    }

    @Test("Logging out is reported as the log out button, on the account screen")
    func logOut() async {
        await makeViewModel().didTapLogOut(in: .screen("account"))

        #expect(taps.events == [.tapped("log_out", in: .screen("account"))])
    }

    @Test("Opening your orders is counted and goes to your orders")
    func orders() {
        makeViewModel().didTapOrders(in: .screen("account"))

        #expect(taps.events == [.tapped("your_orders", in: .screen("account"))])
        #expect(navigation.openedOrderHistory == 1)
    }

    @Test("Opening settings is counted and goes to settings")
    func settings() {
        makeViewModel().didTapSettings(in: .screen("account"))

        #expect(taps.events == [.tapped("settings", in: .screen("account"))])
        #expect(navigation.openedSettings == 1)
    }
}
