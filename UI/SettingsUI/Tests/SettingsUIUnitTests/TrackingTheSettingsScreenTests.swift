import Foundation
import SettingsTestSupport
import Testing
import Settings
import Tracking
import TrackingTestSupport
@testable import SettingsUI

@MainActor
@Suite("What the settings screen tells the shop")
struct TrackingTheSettingsScreenTests {
    private let screens = SpyTrackScreenViewUseCase()
    private let taps = SpyTrackElementInteractionUseCase()

    private func makeViewModel() -> SettingsScreenViewModel {
        SettingsScreenViewModel(
            observeOfferedSettings: SpyObserveOfferedSettingsUseCase(),
            setSetting: SpySetSettingUseCase(),
            trackScreenView: screens,
            trackElementInteraction: taps
        )
    }

    @Test("Coming to Settings is a view of the settings screen")
    func screenView() {
        makeViewModel().didAppear(in: .screen("settings"))

        #expect(screens.events == [.screenViewed("settings")])
    }

    @Test("Turning a switch off reports that switch, left off, on the settings screen")
    func toggleOff() {
        makeViewModel().didToggle(.bagPriceIncreases, to: false, in: .screen("settings"))

        #expect(taps.events == [
            .tapped("bag_price_increases_off", in: .screen("settings"))
        ])
    }

    @Test("Every switch is reported under a name of its own", arguments: [
        (SettingKey.pushNotifications, "push_notifications"),
        (.bagOutOfStockNotice, "bag_out_of_stock_notice"),
        (.bagPriceIncreases, "bag_price_increases"),
        (.bagPriceDecreases, "bag_price_decreases"),
        (.favoritesWaitlistSection, "favorites_waitlist_section"),
        (.favoritesBackInStockSection, "favorites_back_in_stock_section")
    ])
    func everySwitchHasAName(_ example: (SettingKey, String)) {
        makeViewModel().didToggle(example.0, to: true, in: .screen("settings"))

        #expect(taps.events == [.tapped(example.1 + "_on", in: .screen("settings"))])
    }
}
