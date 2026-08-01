import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("Loading and trouble, for the whole feed", .serialized)
/// `ShoppingTheCatalogTests` already settled the principle this suite carries onto Home: "a shopper
/// who cannot reach the shop is told, rather than shown an empty catalog." Home draws that line in
/// one place only — whether nothing was drawn because the shop could not be reached, because every
/// category failed, or because no category had enough to fill a carousel, a shopper is told the same
/// thing and offered the same way back. Only a feed with carousels in it is a loaded Home.
struct LoadingAndTroubleForTheFeedTests {
    // HomeFeedCarousels-08: A shopper who cannot reach the shop at all is told, not shown an empty
    // Home.
    @Test("A shopper who cannot reach the shop at all is told, not shown an empty Home")
    func cannotReachTheShop() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-09: Trying again once the shop answers shows what Home would have shown
    // from the start.
    @Test("Trying again once the shop answers shows what Home would have shown from the start")
    func retryAfterFailure() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true
        await shopper.opensHome()
        shopper.shop.cannotBeReached = false
        shopper.sells(.beauty, products(1...5, category: "beauty"))

        await shopper.triesAgain()

        #expect(shopper.carouselsShown.map(\.category.name) == ["Beauty"])
        #expect(!shopper.isOfferedAnotherGo)
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

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-11: A shop with no categories to organise leaves Home with nothing to draw,
    // which a shopper is told about the same way as a shop that could not be reached.
    @Test("A shop with no categories at all leaves Home with nothing to draw, and says so")
    func noCategoriesLeavesNothingToDraw() async {
        let shopper = Shopper()

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-18: Categories that exist but never clear the floor leave Home with nothing
    // to draw either — a shopper is never shown a Home that is merely blank.
    @Test("A category that never clears the floor leaves Home with nothing to draw, and says so")
    func fallingShortOfTheFloorLeavesNothingToDraw() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...3, category: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-19: A category failing while the shop's only other category falls short of
    // the floor is the same outcome once more — nothing was drawn, so nothing is shown.
    @Test("A category failing, while another falls short of the floor, still leaves nothing to draw")
    func oneFailureAmongShortfallsLeavesNothingToDraw() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...103, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-20: Trying again from the failure screen re-runs the whole draw, categories
    // included — not just the carousels that failed.
    @Test("Trying again after every carousel fails asks the shop for its categories again too")
    func retryAsksForCategoriesAgainToo() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))
        await shopper.opensHome()

        await shopper.triesAgain()

        #expect(shopper.shop.categoriesAskedCount == 2)
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

        await shopper.opensHome()

        #expect(shopper.carouselsShown.map(\.category.name) == ["Beauty"])
        #expect(!shopper.isOfferedAnotherGo)
    }
}
