import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("What a shopper can do from a carousel")
/// A card on Home is the same card as anywhere else in the shop, and leads to the same place.
struct WhatAShopperCanDoTests {
    // HomeFeedCarousels-16: Tapping a product in a carousel opens its details, the same as tapping
    // it anywhere else in the shop.
    @Test("Tapping a product in a carousel opens its details")
    func tappingAProductOpensIt() async throws {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        await shopper.opensHome()
        let product = try #require(shopper.carouselsShown.first?.products.first)

        shopper.selects(product)

        #expect(shopper.navigation.openedProducts == [product.id])
    }
}
