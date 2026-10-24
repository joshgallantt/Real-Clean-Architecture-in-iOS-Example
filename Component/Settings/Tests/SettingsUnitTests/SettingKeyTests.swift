import Foundation
import Testing
@testable import Settings

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
