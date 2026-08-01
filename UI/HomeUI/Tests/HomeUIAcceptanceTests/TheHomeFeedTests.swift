import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("The home feed shows carousels, not one list")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: named for what replaced the flat list
/// on Home, from the shopper's side of the screen.
struct TheHomeFeedTests {
    // HomeFeedCarousels-01: Opening Home shows a carousel per category, not one list mixing every
    // category together.
    @Test("Opening Home shows a carousel per category, not one list mixing every category together")
    func showsCarouselsNotAList() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...6, category: "beauty"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.map(\.category.name) == ["Beauty"])
    }
}

@MainActor
@Suite("How many carousels, and which categories")
struct HowManyCarouselsTests {
    // HomeFeedCarousels-02: Exactly 3 categories means a carousel for every one of them.
    @Test("Exactly 3 categories means a carousel for every one of them")
    func exactlyFewCategories() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...6, category: "beauty"))
        shopper.sells(.fragrances, products(101...106, category: "fragrances"))
        shopper.sells(.furniture, products(201...206, category: "furniture"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(Set(home.carousels.map(\.category.name)) == ["Beauty", "Fragrances", "Furniture"])
        #expect(home.carousels.count == 3)
    }

    // HomeFeedCarousels-03: Fewer than 3 categories means one carousel per category that exists,
    // and nothing stands in for the carousels the shop cannot offer.
    @Test("Fewer than 3 categories means one carousel per category that exists, and nothing more")
    func fewerThanFewCategories() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...6, category: "beauty"))
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.count == 1)
        #expect(home.carousels.first?.category.name == "Beauty")
    }

    // HomeFeedCarousels-04: More than 3 categories means only 3 are shown, and each is a real,
    // distinct one of the shop's own categories.
    @Test("More than 3 categories means only 3 are shown, and each is a real one")
    func moreThanFewCategories() async {
        let shopper = Shopper()
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports]
        for category in categories {
            shopper.sells(category, products(1...10, category: category.id.rawValue))
        }
        let home = shopper.opensHome()

        await home.onAppear()

        #expect(home.carousels.count == 3)
        let shown = Set(home.carousels.map(\.category.id))
        #expect(shown.count == 3)
        #expect(shown.isSubset(of: Set(categories.map(\.id))))
    }

    // HomeFeedCarousels-05: The choice of categories does not change while the shopper stays on
    // Home — drawn once, held stable, not reshuffled on every visit.
    @Test("The choice of categories does not change while the shopper stays on Home")
    func stableWhileOnHome() async {
        let shopper = Shopper()
        let categories: [ProductCategory] = [.beauty, .fragrances, .furniture, .kitchen, .sports]
        for category in categories {
            shopper.sells(category, products(1...10, category: category.id.rawValue))
        }
        let home = shopper.opensHome()
        await home.onAppear()
        let firstVisit = home.carousels.map(\.category.id)

        await home.onAppear()

        #expect(home.carousels.map(\.category.id) == firstVisit)
        #expect(shopper.shop.categoriesAskedCount == 1)
    }
}
