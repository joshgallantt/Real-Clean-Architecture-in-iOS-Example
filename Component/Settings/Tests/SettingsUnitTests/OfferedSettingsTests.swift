import Foundation
import Testing
@testable import Settings

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
