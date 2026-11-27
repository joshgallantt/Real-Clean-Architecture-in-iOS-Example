import Foundation
import Testing
import Settings

@MainActor
@Suite("A setting shows or hides its section")
/// Two of the settings each name one section of a screen. What this component owes those screens is
/// a straight answer to "is it on?" — asked about one setting, and current the moment it is asked.
struct ASettingShowsOrHidesItsSectionTests {
    @Test(
        "A section is shown until its shopper turns it off",
        arguments: [SettingKey.bagChangesSection, .favoritesStockAlertsSection]
    )
    func shownUntilTurnedOff(_ key: SettingKey) async {
        let shopper = Shopper(signedInAs: 42)
        #expect(shopper.sees(key) == true)

        await shopper.turn(key, false)

        #expect(shopper.sees(key) == false)
    }

    @Test("Turning one section off leaves the other shown")
    func oneSectionAtATime() async {
        let shopper = Shopper(signedInAs: 42)

        await shopper.turn(.bagChangesSection, false)

        #expect(shopper.sees(.favoritesStockAlertsSection) == true)
    }

    @Test("A guest, who cannot turn the stock alerts off, is told they are shown")
    func guestIsToldTheDefault() async {
        let shopper = Shopper()

        await shopper.turn(.favoritesStockAlertsSection, false)

        #expect(shopper.sees(.favoritesStockAlertsSection) == true)
    }

    @Test("A section a shopper turned off is still off when they come back")
    func stillOffAfterLeaving() async {
        let shopper = Shopper(signedInAs: 42)
        await shopper.turn(.bagChangesSection, false)

        let returning = shopper.leaveAndComeBack()

        #expect(returning.sees(.bagChangesSection) == false)
    }
}
