import Foundation
import Testing
@testable import Settings

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the aggregate's own rules, stated one at a
/// time. The acceptance suite says a shopper turned something on; these say what turning the same
/// thing on twice does, and which of the six keys the sign-in rule actually applies to.
@Suite("Settings")
struct SettingsTests {
    @Test("A new Settings starts at the app's defaults")
    func defaults() {
        let settings = Settings()

        #expect(settings.value(for: .pushNotifications) == false)
        #expect(settings.value(for: .bagOutOfStockNotice) == true)
        #expect(settings.value(for: .bagPriceIncreases) == true)
        #expect(settings.value(for: .bagPriceDecreases) == true)
        #expect(settings.value(for: .favoritesWaitlistSection) == true)
        #expect(settings.value(for: .favoritesBackInStockSection) == true)
    }

    @Test("Setting one key changes only that key", arguments: SettingKey.allCases)
    func settingOneKeyChangesOnlyThatKey(_ key: SettingKey) {
        let before = Settings()

        let after = before.setting(key, to: !before.value(for: key))

        #expect(after.value(for: key) == !before.value(for: key))
        for other in SettingKey.allCases where other != key {
            #expect(after.value(for: other) == before.value(for: other))
        }
    }

    @Test("Setting a key never changes the value it was asked of")
    func sideEffectFree() {
        let before = Settings()
        _ = before.setting(.pushNotifications, to: true)

        #expect(before.value(for: .pushNotifications) == false)
    }

    @Test("Two Settings holding the same values are the same")
    func equality() {
        #expect(Settings() == Settings())
        #expect(Settings().setting(.pushNotifications, to: true) != Settings())
    }
}

@Suite("SettingKey")
struct SettingKeyTests {
    @Test(
        "Each key belongs to exactly one section",
        arguments: [
            (SettingKey.pushNotifications, SettingsSection.notifications),
            (.bagOutOfStockNotice, .bag),
            (.bagPriceIncreases, .bag),
            (.bagPriceDecreases, .bag),
            (.favoritesWaitlistSection, .favorites),
            (.favoritesBackInStockSection, .favorites)
        ] as [(SettingKey, SettingsSection)]
    )
    func section(_ example: (SettingKey, SettingsSection)) {
        #expect(example.0.section == example.1)
    }

    @Test(
        "Only a favorites key requires being signed in",
        arguments: SettingKey.allCases
    )
    func requiresAuthentication(_ key: SettingKey) {
        #expect(key.requiresAuthentication == (key.section == .favorites))
    }
}

/// The one place the sign-in rule is stated. `SetSettingUseCase` refuses what these leave out and
/// `ObserveOfferedSettingsUseCase` publishes what they return, so what a shopper is offered and
/// what they are allowed cannot drift apart.
@Suite("The settings a shopper is offered")
struct OfferedSettingsTests {
    @Test("A guest is offered every setting that does not need an account", arguments: SettingKey.allCases)
    func aGuestIsOfferedTheRest(_ key: SettingKey) {
        #expect(SettingKey.offered(signedIn: false).contains(key) == !key.requiresAuthentication)
    }

    @Test("A signed-in shopper is offered all of them")
    func signedInIsOfferedAllOfThem() {
        #expect(SettingKey.offered(signedIn: true) == SettingKey.allCases)
    }

    @Test("Each one carries the value the shopper's settings hold", arguments: SettingKey.allCases)
    func eachCarriesItsValue(_ key: SettingKey) {
        let flipped = Settings().setting(key, to: !Settings().value(for: key))

        let offered = Setting.offered(from: flipped, signedIn: true)

        #expect(offered.map(\.key) == SettingKey.allCases)
        for setting in offered {
            #expect(setting.isOn == flipped.value(for: setting.key))
        }
    }

    @Test("A guest is not handed a value for a setting they are not offered", arguments: SettingKey.allCases)
    func aGuestIsHandedNoFavorites(_ key: SettingKey) {
        let offered = Setting.offered(from: Settings(), signedIn: false)

        #expect(offered.contains { $0.key == key } == !key.requiresAuthentication)
    }
}
