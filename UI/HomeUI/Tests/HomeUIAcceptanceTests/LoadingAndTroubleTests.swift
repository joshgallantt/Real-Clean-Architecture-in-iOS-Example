import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("Loading and trouble, for the whole feed", .serialized)
/// `ShoppingTheCatalogTests` already settled the principle this suite carries onto Home: "a shopper
/// who cannot reach the shop is told, rather than shown an empty catalog." Whether the categories
/// themselves fail, every category the feed tried fails once it has them, or a category fails
/// alongside another that merely falls short of the floor, all three read as the shop being
/// unreachable. A shop that answers with no categories at all — or with categories that never clear
/// the floor, nothing having gone wrong along the way — is a different fact: Home genuinely has
/// nothing to show, and is told that instead. The two must never read alike: a shopper whose signal
/// dropped must never be told the shop is empty.
struct LoadingAndTroubleForTheFeedTests {
    // HomeFeedCarousels-08: A shopper who cannot reach the shop at all is told, not shown an empty
    // Home.
    @Test("A shopper who cannot reach the shop at all is told, not shown an empty Home")
    func cannotReachTheShop() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isToldTheShopCannotBeReached)
        #expect(!shopper.seesNothingHereYet)
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
        #expect(shopper.isToldTheShopCannotBeReached)
        #expect(!shopper.seesNothingHereYet)
    }

    // HomeFeedCarousels-11: If the shop genuinely has nothing to organise into categories, that is
    // not a failure — retrying would not change anything, so nothing offers to.
    @Test("If the shop genuinely has nothing to organise into categories, that is not a failure")
    func noCategoriesIsNotAFailure() async {
        let shopper = Shopper()

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.seesNothingHereYet)
        #expect(!shopper.isToldTheShopCannotBeReached)
    }

    // HomeFeedCarousels-18: A category that never clears the floor, with nothing having gone wrong
    // getting there, is the same fact as no categories at all — nothing to show, not trouble.
    @Test("A category that never clears the floor, with nothing gone wrong, is not a failure")
    func fallingShortOfTheFloorWithNoFailureIsNotAFailure() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...3, category: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.seesNothingHereYet)
        #expect(!shopper.isToldTheShopCannotBeReached)
    }

    // HomeFeedCarousels-19: A category failing to load, while the shop's only other category merely
    // falls short of the floor, still reads as the shop being unreachable — something did go wrong,
    // even though it was not the only reason nothing was drawn.
    @Test("A category failing to load, while another merely falls short of the floor, still reads as trouble")
    func oneFailureAmongShortfallsIsStillAFailure() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...103, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isToldTheShopCannotBeReached)
        #expect(!shopper.seesNothingHereYet)
    }

    // HomeFeedCarousels-20: Reloading from the error screen re-runs the whole draw, categories
    // included — not just the carousels that failed.
    @Test("Reloading after every carousel fails asks the shop for its categories again too")
    func reloadAsksForCategoriesAgainToo() async {
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
        #expect(!shopper.isToldTheShopCannotBeReached)
    }
}
