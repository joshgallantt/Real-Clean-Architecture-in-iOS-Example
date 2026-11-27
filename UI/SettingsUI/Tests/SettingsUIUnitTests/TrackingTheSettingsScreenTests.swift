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

        #expect(screens.events == [TrackingEvent(name: .screenViewed, context: .screen("settings"), items: [], properties: [:])])
    }

    @Test("Turning a switch off reports that switch, left off, on the settings screen")
    func toggleOff() {
        makeViewModel().didToggle(.bagChangesSection, to: false, in: .screen("settings"))

        #expect(taps.events == [
            TrackingEvent(name: .elementSelected, context: .screen("settings"), items: [], properties: ["element": "bag_changes_section_off"])
        ])
    }

    @Test("Every switch is reported under a name of its own", arguments: [
        (SettingKey.pushNotifications, "push_notifications"),
        (.bagChangesSection, "bag_changes_section"),
        (.favoritesStockAlertsSection, "favorites_stock_alerts_section")
    ])
    func everySwitchHasAName(_ example: (SettingKey, String)) {
        makeViewModel().didToggle(example.0, to: true, in: .screen("settings"))

        #expect(taps.events == [TrackingEvent(name: .elementSelected, context: .screen("settings"), items: [], properties: ["element": example.1 + "_on"])])
    }
}
