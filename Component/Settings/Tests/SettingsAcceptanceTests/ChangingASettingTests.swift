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
        let before = shopper.offered

        await shopper.turn(key, !(shopper.isOn(key) ?? false))

        for other in before.map(\.key) where other != key {
            #expect(shopper.isOn(other) == before.first { $0.key == other }?.isOn)
        }
        #expect(shopper.isOn(key) == !(before.first { $0.key == key }?.isOn ?? false))
    }

    // SettingsMenu-04: A changed setting is still changed the next time the shopper's settings are
    // read — it survives leaving and coming back.
    @Test("A changed setting survives leaving and coming back")
    func changeIsRemembered() async {
        let shopper = Shopper()

        await shopper.turn(.pushNotifications, true)
        let returning = shopper.leaveAndComeBack()

        #expect(returning.isOn(.pushNotifications) == true)
    }
}
