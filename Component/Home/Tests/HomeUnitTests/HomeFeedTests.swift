import Foundation
import ProductTestSupport
import Testing
import Product
@testable import Home

@Suite("A home feed")
/// The invariant `HomeFeed` leans on: it cannot be built with nothing in it, so a draw that came
/// back with nothing has no feed to hand back.
struct HomeFeedTests {
    @Test("A feed with no carousels is not a feed")
    func noCarouselsIsNotAFeed() {
        #expect(HomeFeed(carousels: []) == nil)
    }

    @Test("A feed keeps the carousels it was drawn with, in order")
    func keepsItsCarouselsInOrder() {
        let beauty = HomeCarousel(category: .beauty, products: products(1...5, category: "beauty"))
        let fragrances = HomeCarousel(category: .fragrances, products: products(101...105, category: "fragrances"))

        #expect(HomeFeed(carousels: [beauty, fragrances])?.carousels == [beauty, fragrances])
    }
}
