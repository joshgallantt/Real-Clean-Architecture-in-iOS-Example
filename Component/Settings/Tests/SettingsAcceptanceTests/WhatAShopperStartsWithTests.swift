import Foundation
import Testing
import Settings

@MainActor
@Suite("What a shopper starts with")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken expectation rather than a broken method.
struct WhatAShopperStartsWithTests {
    // SettingsMenu-01: A guest's settings start at the app's defaults — push notifications off,
    // every bag notice shown.
    @Test("A guest's settings start at the app's defaults — push notifications off, every bag notice shown")
    func guestDefaults() {
        let shopper = Shopper()

        #expect(shopper.isOn(.pushNotifications) == false)
        #expect(shopper.isOn(.bagOutOfStockNotice) == true)
        #expect(shopper.isOn(.bagPriceIncreases) == true)
        #expect(shopper.isOn(.bagPriceDecreases) == true)
    }

    // SettingsMenu-02: A newly signed-in shopper's settings start at the same defaults, including
    // both favorites settings.
    @Test("A newly signed-in shopper's settings start at the same defaults, including favorites")
    func signedInDefaults() {
        let shopper = Shopper(signedInAs: 42)

        #expect(shopper.isOn(.pushNotifications) == false)
        #expect(shopper.isOn(.bagOutOfStockNotice) == true)
        #expect(shopper.isOn(.bagPriceIncreases) == true)
        #expect(shopper.isOn(.bagPriceDecreases) == true)
        #expect(shopper.isOn(.favoritesWaitlistSection) == true)
        #expect(shopper.isOn(.favoritesBackInStockSection) == true)
    }

    // A guest is not shown the favorites settings at all, which is why nothing above asks what they
    // are set to: there is no value to show somebody who is not offered the setting.
    @Test("A guest is not shown the favorites settings at all")
    func guestIsNotShownFavorites() {
        let shopper = Shopper()

        #expect(shopper.isOn(.favoritesWaitlistSection) == nil)
        #expect(shopper.isOn(.favoritesBackInStockSection) == nil)
    }
}
