import Foundation
import Testing
import Settings
@testable import SettingsUI

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the screen's own rules, driven through its
/// seams rather than the Shopper testing API. The acceptance suite says what a shopper sees and
/// taps; these say what the view model does with what it is handed.
@MainActor
@Suite("Settings screen")
struct SettingsScreenViewModelTests {
    private func makeViewModel(
        observeOfferedSettings: StubObserveOfferedSettings = StubObserveOfferedSettings(),
        setSetting: SpySetSetting = SpySetSetting()
    ) -> SettingsScreenViewModel {
        SettingsScreenViewModel(
            observeOfferedSettings: observeOfferedSettings,
            setSetting: setSetting
        )
    }

    private func makeViewModel(showing settings: [Setting]) -> SettingsScreenViewModel {
        makeViewModel(observeOfferedSettings: StubObserveOfferedSettings(settings))
    }

    @Test("Settings a guest has become Notifications and Bag, and no Favorites section")
    func guestSectionsExcludeFavorites() {
        let viewModel = makeViewModel(showing: Setting.offered(from: Settings(), signedIn: false))

        viewModel.onAppear()

        #expect(viewModel.sections.map(\.id) == [.notifications, .bag])
    }

    @Test("Settings a signed-in shopper has become all three sections, Favorites last")
    func signedInSectionsIncludeFavorites() {
        let viewModel = makeViewModel(showing: Setting.offered(from: Settings(), signedIn: true))

        viewModel.onAppear()

        #expect(viewModel.sections.map(\.id) == [.notifications, .bag, .favorites])
    }

    @Test("A section is shown only where the shopper has a setting in it")
    func emptySectionsAreLeftOut() {
        let viewModel = makeViewModel(showing: [Setting(key: .bagPriceIncreases, isOn: true)])

        viewModel.onAppear()

        #expect(viewModel.sections.map(\.id) == [.bag])
        #expect(viewModel.sections.flatMap(\.rows).map(\.id) == [.bagPriceIncreases])
    }

    @Test(
        "Every row is worded for the shopper",
        arguments: [
            (SettingKey.pushNotifications, "Push Notifications"),
            (.bagOutOfStockNotice, "Show Out-of-Stock Notice"),
            (.bagPriceIncreases, "Show Price Increases"),
            (.bagPriceDecreases, "Show Price Decreases"),
            (.favoritesWaitlistSection, "Show Waitlist"),
            (.favoritesBackInStockSection, "Show Back in Stock")
        ] as [(SettingKey, String)]
    )
    func rowWording(_ example: (SettingKey, String)) {
        let viewModel = makeViewModel(showing: Setting.offered(from: Settings(), signedIn: true))

        viewModel.onAppear()

        let row = viewModel.sections.flatMap(\.rows).first { $0.id == example.0 }
        #expect(row?.title == example.1)
    }

    @Test("Every row sits in its own key's section", arguments: SettingKey.allCases)
    func rowsSitInTheirOwnSection(_ key: SettingKey) {
        let viewModel = makeViewModel(showing: Setting.offered(from: Settings(), signedIn: true))

        viewModel.onAppear()

        let section = viewModel.sections.first { $0.rows.contains { $0.id == key } }
        #expect(section?.id == key.section)
    }

    @Test("Every row shows the value it was handed")
    func rowsShowTheValueTheyWereHanded() {
        let handed = Setting.offered(
            from: Settings([.pushNotifications: true, .bagPriceIncreases: false]),
            signedIn: true
        )
        let viewModel = makeViewModel(showing: handed)

        viewModel.onAppear()

        let rows = viewModel.sections.flatMap(\.rows)
        for setting in handed {
            #expect(rows.first { $0.id == setting.key }?.isOn == setting.isOn)
        }
    }

    @Test("It redraws from whatever the shop publishes next")
    func redrawsOnEveryPublish() {
        let observeOfferedSettings = StubObserveOfferedSettings(
            Setting.offered(from: Settings(), signedIn: false)
        )
        let viewModel = makeViewModel(observeOfferedSettings: observeOfferedSettings)
        viewModel.onAppear()

        observeOfferedSettings.send(Setting.offered(from: Settings(), signedIn: true))

        #expect(viewModel.sections.map(\.id) == [.notifications, .bag, .favorites])
    }

    @Test("Appearing subscribes only once, however often it happens")
    func subscribesOnce() {
        let observeOfferedSettings = StubObserveOfferedSettings()
        let viewModel = makeViewModel(observeOfferedSettings: observeOfferedSettings)

        viewModel.onAppear()
        viewModel.onAppear()
        viewModel.onAppear()

        #expect(observeOfferedSettings.callCount == 1)
    }

    @Test("Toggling delegates to the use case with that key and the value it was asked for")
    func togglingDelegates() async {
        let setSetting = SpySetSetting()
        let viewModel = makeViewModel(setSetting: setSetting)

        viewModel.didToggle(.bagPriceDecreases, to: false)
        await settle()

        #expect(setSetting.calls.map(\.key) == [.bagPriceDecreases])
        #expect(setSetting.calls.map(\.isOn) == [false])
    }
}
