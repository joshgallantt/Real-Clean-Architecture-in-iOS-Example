import Foundation
import Testing
import Settings

@MainActor
@Suite("Settings belong to whoever is signed in")
/// Mirrors how the bag itself already treats an owner switch, applied to preferences instead of a
/// bag: the guest and each account keep their own settings, independently and durably, and nothing
/// is inherited by crossing between them.
struct SettingsBelongToWhoeverIsSignedInTests {
    // SettingsMenu-08: A shopper's settings are still there when they come back.
    @Test(
        "A shopper's settings are still there when they come back",
        arguments: SettingKey.allCases
    )
    func settingsSurviveLeaving(_ key: SettingKey) async {
        let defaults = Settings()
        let shopper = Shopper(signedInAs: 42)
        await shopper.turn(key, !defaults.value(for: key))

        let returning = shopper.leaveAndComeBack()

        #expect(returning.settings.value(for: key) == !defaults.value(for: key))
        for other in SettingKey.allCases where other != key {
            #expect(returning.settings.value(for: other) == defaults.value(for: other))
        }
    }

    // SettingsMenu-09: Two shoppers do not see each other's settings.
    @Test("Two shoppers do not see each other's settings")
    func settingsAreNotShared() async {
        let shopper = Shopper(signedInAs: 1)
        await shopper.turn(.pushNotifications, true)

        shopper.signIn(asUserId: 2)
        #expect(shopper.settings.value(for: .pushNotifications) == false)

        shopper.signIn(asUserId: 1)
        #expect(shopper.settings.value(for: .pushNotifications) == true)
    }

    // SettingsMenu-10: Signing in and back out again does not carry settings between the guest and
    // the account in either direction.
    @Test("Signing in and back out again does not carry settings between the guest and the account")
    func guestAndAccountSettingsAreKeptApart() async {
        let shopper = Shopper()
        await shopper.turn(.pushNotifications, true)

        shopper.signIn(asUserId: 42)
        #expect(shopper.settings.value(for: .pushNotifications) == false)

        await shopper.turn(.bagPriceIncreases, false)
        shopper.signOut()

        #expect(shopper.settings.value(for: .pushNotifications) == true)
        #expect(shopper.settings.value(for: .bagPriceIncreases) == true)
    }
}
