import Foundation
import Testing
import Product

@MainActor
@Suite("How many carousels, and which categories")
/// The user's own words: "pick random categories until 5 can be shown". Home tries the shop's
/// categories in a random order it draws fresh each time, one at a time, never trying the same
/// category twice, until either 5 have earned a carousel or there are no more categories left to
/// try — whichever comes first.
struct HowManyCarouselsTests {
    // HomeFeed-02: Exactly 5 qualifying categories means a carousel for every one of them.
    @Test("Exactly 5 qualifying categories means a carousel for every one of them")
    func exactlyFiveQualifyingCategories() async {
        let shopper = Shopper()
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports]
        for category in categories {
            shopper.sells(category, products(1...6, category: category.id.rawValue))
        }

        await shopper.opensHome()

        #expect(Set(shopper.carouselsShown.map(\.category.id)) == Set(categories.map(\.id)))
        #expect(shopper.carouselsShown.count == 5)
    }

    // HomeFeed-03: Fewer than 5 qualifying categories means one carousel per category that
    // exists, and nothing stands in for the carousels the shop cannot offer.
    @Test("Fewer than 5 qualifying categories means one carousel per category that exists, and nothing more")
    func fewerThanFiveQualifyingCategories() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...6, category: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.count == 1)
        #expect(shopper.carouselsShown.first?.category.name == "Beauty")
        #expect(!shopper.homeCouldNotBeDrawn)
    }

    // HomeFeed-04: More than 5 qualifying categories means only 5 are shown, and each is a real,
    // distinct one of the shop's own categories.
    @Test("More than 5 qualifying categories means only 5 are shown, and each is a real one")
    func moreThanFiveQualifyingCategories() async {
        let shopper = Shopper()
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports, .toys, .books]
        for category in categories {
            shopper.sells(category, products(1...10, category: category.id.rawValue))
        }

        await shopper.opensHome()

        #expect(shopper.carouselsShown.count == 5)
        let shown = Set(shopper.carouselsShown.map(\.category.id))
        #expect(shown.count == 5)
        #expect(shown.isSubset(of: Set(categories.map(\.id))))
    }

    // HomeFeed-05: A category that falls short of the floor does not shrink the result — another
    // category is tried in its place, so long as one remains untried.
    @Test("A category that falls short does not shrink the result, when another remains to try")
    func aShortfallIsBackfilledByAnotherCategory() async {
        let shopper = Shopper()
        let qualifying: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports]
        for category in qualifying {
            shopper.sells(category, products(1...10, category: category.id.rawValue))
        }
        shopper.sells(.toys, products(1...3, category: "toys"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.count == 5)
        #expect(Set(shopper.carouselsShown.map(\.category.id)) == Set(qualifying.map(\.id)))
    }

    // HomeFeed-06: Once 5 categories have qualified, Home stops — it never asks the shop about a
    // category it did not need.
    @Test("Home never asks about a category it did not need, once 5 have qualified")
    func neverAsksAboutMoreCategoriesThanItNeeded() async {
        let shopper = Shopper()
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports, .toys]
        for category in categories {
            shopper.sells(category, products(1...10, category: category.id.rawValue))
        }

        await shopper.opensHome()

        #expect(shopper.carouselsShown.count == 5)
        #expect(shopper.shop.categoryProductRequests.count == 5)
    }
}
