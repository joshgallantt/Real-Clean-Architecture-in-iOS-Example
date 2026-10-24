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
