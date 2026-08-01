import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("Loading and trouble, for the whole feed", .serialized)
/// `ShoppingTheCatalogTests` already settled the principle this suite carries onto Home: "a shopper
/// who cannot reach the shop is told, rather than shown an empty catalog." Whether the categories
/// themselves fail, or every category the feed tried fails once it has them, both read as the shop
/// being unreachable. A shop that answers with no categories at all is a different fact — Home has
/// genuinely nothing to show, and is told that instead.
struct LoadingAndTroubleForTheFeedTests {
    // HomeFeedCarousels-08: A shopper who cannot reach the shop at all is told, not shown an empty
    // Home.
    @Test("A shopper who cannot reach the shop at all is told, not shown an empty Home")
    func cannotReachTheShop() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.isEmpty)
        #expect(shopper.snackbar.shown.first?.title == "Nothing's Loading")
        #expect(shopper.snackbar.shown.first?.action != nil)
    }

    // HomeFeedCarousels-09: Trying again once the shop answers shows what Home would have shown
    // from the start.
    @Test("Trying again once the shop answers shows what Home would have shown from the start")
    func retryAfterFailure() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true
        let home = shopper.opensHome()
        await home.onAppear()
        shopper.shop.cannotBeReached = false
        shopper.sells(.beauty, products(1...5, category: "beauty"))

        shopper.snackbar.shown.first?.action?.handler()
        await settle()

        #expect(home.carousels.map(\.category.name) == ["Beauty"])
    }

    // HomeFeedCarousels-10: If every category the feed tried to show fails to load, that is a
    // failure too, not an empty Home.
    @Test("If every category the feed tried fails to load, that is a failure too, not an empty Home")
    func everyCarouselFailingIsAFeedFailure() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "fragrances"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.isEmpty)
        #expect(shopper.snackbar.shown.first?.title == "Nothing's Loading")
    }

    // HomeFeedCarousels-11: If the shop genuinely has nothing to organise into categories, that is
    // not a failure — retrying would not change anything, so nothing offers to.
    @Test("If the shop genuinely has nothing to organise into categories, that is not a failure")
    func noCategoriesIsNotAFailure() async {
        let shopper = Shopper()
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.isEmpty)
        #expect(home.isEmpty == true)
        #expect(shopper.snackbar.shown.isEmpty)
    }
}

@MainActor
@Suite("Loading and trouble, for one carousel", .serialized)
struct LoadingAndTroubleForOneCarouselTests {
    // HomeFeedCarousels-12: One category failing to load does not take down the categories that
    // did — it is simply absent, and nothing tells the shopper about it directly.
    @Test("One category failing to load does not take down the categories that did")
    func oneCarouselFailingLeavesTheRest() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "fragrances"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.map(\.category.name) == ["Beauty"])
        #expect(shopper.snackbar.shown.isEmpty)
    }
}
