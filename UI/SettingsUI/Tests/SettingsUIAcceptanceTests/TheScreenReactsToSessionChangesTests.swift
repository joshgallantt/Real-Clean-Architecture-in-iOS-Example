import Foundation
import Testing
import Settings
@testable import SettingsUI

@MainActor
@Suite("The screen reacts the instant the session changes")
/// Mirrors `Component/Settings`'s own "settings react the instant the session changes" — one layer
/// up: what the domain already switches immediately, the screen shows immediately, with no
/// navigation and no reopening.
struct TheScreenReactsToSessionChangesTests {
    // SettingsMenu-19: Signing in while the screen is open makes Favorites appear immediately,
    // already filled in with that account's own settings.
    @Test("Signing in while the screen is open makes Favorites appear immediately, already filled in")
    func signingInShowsFavoritesImmediately() {
        let shopper = Shopper()
        shopper.opensScreen()
        #expect(shopper.sectionsShown == ["Notifications", "Bag"])
        #expect(shopper.isOn(.favoritesWaitlistSection) == nil)

        shopper.signIn(settings: Settings([.favoritesWaitlistSection: false]))

        #expect(shopper.sectionsShown == ["Notifications", "Bag", "Favorites"])
        #expect(shopper.isOn(.favoritesWaitlistSection) == false)
    }

    // SettingsMenu-20: Signing out while the screen is open makes Favorites disappear immediately,
    // and the remaining rows switch to the guest's own settings.
    @Test("Signing out while the screen is open makes Favorites disappear immediately, and the rest switches to the guest's own settings")
    func signingOutHidesFavoritesImmediately() {
        let shopper = Shopper(signedIn: true, settings: Settings([.pushNotifications: true]))
        shopper.opensScreen()
        #expect(shopper.sectionsShown == ["Notifications", "Bag", "Favorites"])

        shopper.signOut(settings: Settings([.pushNotifications: false]))

        #expect(shopper.sectionsShown == ["Notifications", "Bag"])
        #expect(shopper.isOn(.favoritesWaitlistSection) == nil)
        #expect(shopper.isOn(.pushNotifications) == false)
    }
}
