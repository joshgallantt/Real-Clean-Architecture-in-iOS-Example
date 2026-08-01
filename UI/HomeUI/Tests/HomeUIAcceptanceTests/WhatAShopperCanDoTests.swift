import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("What a shopper can do from a carousel")
struct WhatAShopperCanDoTests {
    // HomeFeedCarousels-16: Tapping a product in a carousel opens its details, the same as tapping
    // it anywhere else in the shop.
    @Test("Tapping a product in a carousel opens its details")
    func tappingAProductOpensIt() async throws {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        let home = shopper.opensHome()
        await home.onAppear()
        let product = try #require(home.carousels.first?.products.first)

        home.didSelect(product)

        #expect(shopper.navigation.openedProducts == [product.id])
    }

    // HomeFeedCarousels-17: Reaching the end of a carousel does not fetch more for that category —
    // a carousel holds at most 10 and stops there; seeing more is what View All is for.
    @Test("Reaching the end of a carousel does not fetch more for that category")
    func noFurtherPagingWithinACarousel() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...20, category: "beauty"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.first?.products.count == 10)
        #expect(shopper.shop.categoryProductRequests.filter { $0 == CategoryID(rawValue: "beauty") }.count == 1)
    }
}
