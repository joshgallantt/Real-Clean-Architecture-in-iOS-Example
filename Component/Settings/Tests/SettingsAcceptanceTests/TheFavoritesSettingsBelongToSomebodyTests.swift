import Foundation
import Testing
import Settings

@MainActor
@Suite("The favorites settings belong to somebody")
/// Requiring an account is a business rule, so it is met here as a shopper meets it — as an answer
/// from the operation they attempted, not as a check they had to remember to make first. Mirrors
/// `Wishlist`'s own "a wishlist belongs to somebody" suite: the favorites settings describe sections
/// of a tab a guest cannot open at all, so there is nobody for them to belong to yet.
struct TheFavoritesSettingsBelongToSomebodyTests {
    // SettingsMenu-05: A guest is asked to sign in rather than quietly having a favorites setting
    // ignored.
    @Test(
        "A guest is asked to sign in rather than quietly having a favorites setting ignored",
        arguments: [SettingKey.favoritesWaitlistSection, .favoritesBackInStockSection]
    )
    func guestIsAskedToSignIn(_ key: SettingKey) async {
        let shopper = Shopper()

        let outcome = await shopper.turn(key, false)

        #expect(outcome.failure == .unauthenticated)
        /// That the refusal left the record exactly as it was is asserted in `SetSettingUseCaseTests`
        /// rather than here. A guest is not shown this setting at all, so there is nothing a shopper
        /// could look at to see it — and a suite that speaks their language cannot assert on a value
        /// no shopper is ever handed.
        #expect(shopper.isOn(key) == nil)
    }

    // SettingsMenu-06: Signing in after being refused, the shopper can now change the setting they
    // were after.
    @Test("Signing in after being refused, the shopper can now change the setting they were after")
    func signingInThenChanging() async {
        let shopper = Shopper()
        #expect(await shopper.turn(.favoritesWaitlistSection, false).failure == .unauthenticated)

        shopper.signIn(asUserId: 42)

        #expect(await shopper.turn(.favoritesWaitlistSection, false).failure == nil)
        #expect(shopper.isOn(.favoritesWaitlistSection) == false)
    }

    // SettingsMenu-07: Signing back out refuses the favorites settings again — the rule follows the
    // session, not a single ask.
    @Test("Signing back out refuses the favorites settings again")
    func signingOutRefusesAgain() async {
        let shopper = Shopper(signedInAs: 42)
        await shopper.turn(.favoritesWaitlistSection, false)

        shopper.signOut()

        #expect(await shopper.turn(.favoritesWaitlistSection, true).failure == .unauthenticated)
    }
}
