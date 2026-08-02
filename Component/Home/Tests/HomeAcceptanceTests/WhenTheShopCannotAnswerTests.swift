import Foundation
import Testing
import Product

@MainActor
@Suite("When the shop cannot answer", .serialized)
/// A shop that cannot be reached and a shop with nothing worth drawing both leave Home with
/// nothing to show — the same failure, told the same way, however it came about.
struct WhenTheShopCannotAnswerTests {
    // HomeFeed-10: A shop that cannot be reached at all leaves Home with nothing to draw.
    @Test("A shop that cannot be reached at all leaves Home with nothing to draw")
    func cannotReachTheShop() async {
        let shopper = Shopper()
        shopper.shop.cannotBeReached = true

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-11: If every category the feed tried fails to load, that is a failure too, not a
    // Home with nothing on it.
    @Test("If every category tried fails to load, that is a failure too, not an empty Home")
    func everyCategoryTriedFailsToLoad() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "fragrances"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-12: A shop with no categories to organise leaves Home with nothing to draw.
    @Test("A shop with no categories at all leaves Home with nothing to draw")
    func noCategoriesAtAll() async {
        let shopper = Shopper()

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-13: One category failing to load does not take down the categories that did.
    @Test("One category failing to load does not take down the categories that did")
    func oneCategoryFailingLeavesTheRest() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "fragrances"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.map(\.category.name) == ["Beauty"])
        #expect(!shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-14: A category that never clears the floor, alone, leaves Home with nothing to
    // draw either — a shopper is never shown a Home that is merely blank.
    @Test("A category that never clears the floor leaves Home with nothing to draw")
    func fallingShortOfTheFloorLeavesNothingToDraw() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...3, category: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-15: A category failing, while the shop's only other category falls short of the
    // floor, still leaves nothing to draw.
    @Test("A category failing, while another falls short of the floor, still leaves nothing to draw")
    func oneFailureAmongShortfallsLeavesNothingToDraw() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...103, category: "fragrances"))
        shopper.shop.makeUnreachable(CategoryID(rawValue: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.homeCouldNotBeDrawn)
    }
}
