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

        #expect(shopper.settings.value(for: .pushNotifications) == false)
        #expect(shopper.settings.value(for: .bagOutOfStockNotice) == true)
        #expect(shopper.settings.value(for: .bagPriceIncreases) == true)
        #expect(shopper.settings.value(for: .bagPriceDecreases) == true)
    }

    // SettingsMenu-02: A newly signed-in shopper's settings start at the same defaults, including
    // both favorites settings.
    @Test("A newly signed-in shopper's settings start at the same defaults, including favorites")
    func signedInDefaults() {
        let shopper = Shopper(signedInAs: 42)

        #expect(shopper.settings.value(for: .pushNotifications) == false)
        #expect(shopper.settings.value(for: .bagOutOfStockNotice) == true)
        #expect(shopper.settings.value(for: .bagPriceIncreases) == true)
        #expect(shopper.settings.value(for: .bagPriceDecreases) == true)
        #expect(shopper.settings.value(for: .favoritesWaitlistSection) == true)
        #expect(shopper.settings.value(for: .favoritesBackInStockSection) == true)
    }
}
