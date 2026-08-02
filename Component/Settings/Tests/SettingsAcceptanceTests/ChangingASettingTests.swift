import Foundation
import Testing
import Settings

@MainActor
@Suite("Changing a setting")
struct ChangingASettingTests {
    // SettingsMenu-03: Turning a setting changes only that one setting; everything else stays as it
    // was.
    @Test(
        "Turning a setting changes only that one setting",
        arguments: [
            SettingKey.pushNotifications,
            .bagOutOfStockNotice,
            .bagPriceIncreases,
            .bagPriceDecreases
        ]
    )
    func changingOneLeavesTheRest(_ key: SettingKey) async {
        let shopper = Shopper()
        let before = shopper.settings

        await shopper.turn(key, !before.value(for: key))

        for other in SettingKey.allCases where other != key {
            #expect(shopper.settings.value(for: other) == before.value(for: other))
        }
        #expect(shopper.settings.value(for: key) == !before.value(for: key))
    }

    // SettingsMenu-04: A changed setting is still changed the next time the shopper's settings are
    // read — it survives leaving and coming back.
    @Test("A changed setting survives leaving and coming back")
    func changeIsRemembered() async {
        let shopper = Shopper()

        await shopper.turn(.pushNotifications, true)
        let returning = shopper.leaveAndComeBack()

        #expect(returning.settings.pushNotifications == true)
    }
}
