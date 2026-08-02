import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("Loading and trouble", .serialized)
/// What the screen owns once a draw comes back: showing nothing and offering another go when the
/// draw failed, trying again, and not asking twice for what it already has.
struct LoadingAndTroubleTests {
    // HomeFeedCarousels-08: A shopper whose Home could not be drawn is told, not shown an empty
    // Home.
    @Test("A shopper whose Home could not be drawn is told, not shown an empty Home")
    func homeCouldNotBeDrawn() async {
        let shopper = Shopper()
        shopper.theShopCannotDrawAFeed()

        await shopper.opensHome()

        #expect(shopper.carouselsShown.isEmpty)
        #expect(shopper.isOfferedAnotherGo)
    }

    // HomeFeedCarousels-09/-20: Trying again re-runs the whole draw and shows what succeeds this
    // time.
    @Test("Trying again re-runs the draw, and what succeeds this time is shown")
    func retryShowsWhatSucceeds() async {
        let shopper = Shopper()
        shopper.theShopCannotDrawAFeed()
        await shopper.opensHome()
        shopper.sells(.beauty, products(1...5, category: "beauty"))

        await shopper.triesAgain()

        #expect(shopper.carouselsShown.map(\.category.name) == ["Beauty"])
        #expect(!shopper.isOfferedAnotherGo)
        #expect(shopper.drawAttempts == 2)
    }

    // HomeFeedCarousels-05: What Home drew does not change while the shopper stays on it — drawn
    // once per visit, not asked for again just because the screen appeared a second time.
    @Test("Appearing again once Home has loaded does not ask for a fresh draw")
    func doesNotAskAgainOnceLoaded() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        await shopper.opensHome()
        let firstVisit = shopper.carouselsShown

        await shopper.opensHome()

        #expect(shopper.carouselsShown == firstVisit)
        #expect(shopper.drawAttempts == 1)
    }
}
