import Foundation
import Testing
import Settings
@testable import SettingsUI

@MainActor
@Suite("Turning a toggle")
struct TurningAToggleTests {
    // SettingsMenu-17: Turning a toggle writes through immediately — no separate save step.
    @Test("Turning a toggle writes through immediately — no separate save step")
    func togglingWritesThroughImmediately() async {
        let shopper = Shopper()
        shopper.opensScreen()

        shopper.toggles(.pushNotifications, to: true)
        await shopper.settle()

        #expect(shopper.isOn(.pushNotifications) == true)
    }

    // SettingsMenu-18: Turning one toggle leaves every other row exactly as it was.
    @Test("Turning one toggle leaves every other row exactly as it was")
    func togglingOneLeavesTheRest() async {
        let shopper = Shopper(signedIn: true)
        shopper.opensScreen()
        let others = SettingKey.allCases.filter { $0 != .bagPriceIncreases }
        let before = others.map { shopper.isOn($0) }

        shopper.toggles(.bagPriceIncreases, to: false)
        await shopper.settle()

        #expect(others.map { shopper.isOn($0) } == before)
        #expect(shopper.isOn(.bagPriceIncreases) == false)
    }
}
