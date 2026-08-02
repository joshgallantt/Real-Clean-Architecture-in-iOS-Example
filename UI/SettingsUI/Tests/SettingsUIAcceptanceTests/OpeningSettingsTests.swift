import Foundation
import Testing
import Settings
@testable import SettingsUI

@MainActor
@Suite("Opening Settings")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken screen rather than a broken method.
///
/// There is no separate scenario for "a guest is not asked to sign in first" — the screen has no
/// gate to test. `guestSeesNotificationsAndBagOnly` opens it as a guest and gets real sections back,
/// which is what the absence of a gate looks like from here.
struct OpeningSettingsTests {
    // SettingsMenu-14: A guest opening Settings sees Notifications and Bag, in that order, and never
    // sees Favorites.
    @Test("A guest opening Settings sees Notifications and Bag, in that order, and never sees Favorites")
    func guestSeesNotificationsAndBagOnly() {
        let shopper = Shopper()

        shopper.opensScreen()

        #expect(shopper.sectionsShown == ["Notifications", "Bag"])
    }

    // SettingsMenu-15: A signed-in shopper opening Settings sees Notifications, Bag and Favorites,
    // in that order.
    @Test("A signed-in shopper opening Settings sees Notifications, Bag and Favorites, in that order")
    func signedInSeesAllThreeSections() {
        let shopper = Shopper(signedIn: true)

        shopper.opensScreen()

        #expect(shopper.sectionsShown == ["Notifications", "Bag", "Favorites"])
    }

    // SettingsMenu-16: Every row is worded for the shopper, not for the code, and shows its current
    // value.
    @Test("Every row is worded for the shopper, and shows its current value")
    func rowsAreWordedAndCurrent() {
        let shopper = Shopper(
            signedIn: true,
            settings: Settings([.pushNotifications: true, .bagPriceIncreases: false])
        )

        shopper.opensScreen()

        #expect(shopper.rowsShown(in: "Notifications") == ["Push Notifications"])
        #expect(shopper.rowsShown(in: "Bag") == [
            "Show Out-of-Stock Notice",
            "Show Price Increases",
            "Show Price Decreases"
        ])
        #expect(shopper.rowsShown(in: "Favorites") == ["Show Waitlist", "Show Back in Stock"])
        #expect(shopper.isOn(.pushNotifications) == true)
        #expect(shopper.isOn(.bagPriceIncreases) == false)
    }
}
