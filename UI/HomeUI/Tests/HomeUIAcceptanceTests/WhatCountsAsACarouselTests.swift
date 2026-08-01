import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("What counts as a carousel")
/// The floor and the cap the user gave — at least 5 products, never more than 10 — are one rule
/// about what qualifies as a carousel, not two: a category with 0 products and one with 4 both fail
/// the same test below, and both are dropped the same way — not shown short, not backfilled with
/// another category, and not counted toward the 3 carousels shown.
struct WhatCountsAsACarouselTests {
    // HomeFeedCarousels-06: A category needs at least 5 products to earn a carousel; a carousel
    // never shows more than 10. Boundaries at 4, 5 and 10 pin the floor and the cap exactly.
    @Test(
        "A category needs at least 5 products to earn a carousel, and a carousel never shows more than 10",
        arguments: [
            (available: 0, expectedShown: nil),
            (available: 4, expectedShown: nil),
            (available: 5, expectedShown: 5),
            (available: 6, expectedShown: 6),
            (available: 10, expectedShown: 10),
            (available: 15, expectedShown: 10)
        ] as [(available: Int, expectedShown: Int?)]
    )
    func floorAndCap(_ example: (available: Int, expectedShown: Int?)) async {
        let shopper = Shopper()
        let stock = example.available > 0 ? products(1...example.available, category: "beauty") : []
        shopper.sells(.beauty, stock)

        await shopper.opensHome()

        if let expectedShown = example.expectedShown {
            #expect(shopper.carouselsShown.count == 1)
            #expect(shopper.carouselsShown.first?.products.count == expectedShown)
            #expect(!shopper.isOfferedAnotherGo)
        } else {
            #expect(shopper.carouselsShown.isEmpty)
            #expect(shopper.isOfferedAnotherGo)
        }
    }

    // HomeFeedCarousels-07: A product merely out of stock still appears, marked as such — the same
    // rule Component/Product already keeps, carried through to a carousel.
    @Test("A product merely out of stock still appears, marked as such")
    func outOfStockStillAppears() async {
        let shopper = Shopper()
        var items = products(1...5, category: "beauty")
        items[0] = Product.fixture(id: 1, category: "beauty", availability: .outOfStock)
        shopper.sells(.beauty, items)

        await shopper.opensHome()

        #expect(shopper.carouselsShown.first?.products.count == 5)
        #expect(shopper.carouselsShown.first?.products.first?.availability == .outOfStock)
    }
}
