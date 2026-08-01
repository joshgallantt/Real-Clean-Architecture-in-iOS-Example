import Foundation
import Testing
import Product
@testable import HomeUI

@MainActor
@Suite("Seeing all of a category", .serialized)
/// The user's own words: a "View All" button, not "See All". It reuses the category results the
/// shop already offers elsewhere (`Component/Product`'s `BrowseCatalogUseCase`, filtered by
/// category) rather than a second, Home-only category screen — which module supplies that screen is
/// the architect's call, not this suite's. `HomeNavigation` gains the same shape of route
/// `SearchNavigation` already has for it.
struct SeeingAllOfACategoryTests {
    // HomeFeedCarousels-13: View All opens that category's results, not another's.
    @Test("View All opens that category's results, not another's")
    func viewAllOpensItsOwnCategory() async throws {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        let home = shopper.opensHome()
        await home.onAppear()
        let fragrances = try #require(home.carousels.first { $0.category.name == "Fragrances" })

        home.didTapViewAll(for: fragrances)

        #expect(shopper.navigation.openedCatalogs == [.category(.fragrances)])
    }

    // HomeFeedCarousels-14: Every carousel offers a View All button, whether or not the category
    // has more products than the carousel showed.
    @Test("Every carousel offers a View All button that leads to its own category")
    func everyCarouselOffersViewAll() async throws {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        let home = shopper.opensHome()
        await home.onAppear()
        let beauty = try #require(home.carousels.first)

        home.didTapViewAll(for: beauty)

        #expect(shopper.navigation.openedCatalogs == [.category(.beauty)])
    }

    // HomeFeedCarousels-15: Tapping View All does not change what Home itself is showing, so
    // coming back to it shows exactly what was left — same categories, same products, same order.
    @Test("Tapping View All does not change what Home itself is showing")
    func viewAllDoesNotChangeHome() async throws {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        let home = shopper.opensHome()
        await home.onAppear()
        let before = home.carousels
        let beauty = try #require(home.carousels.first)

        home.didTapViewAll(for: beauty)

        #expect(home.carousels == before)
    }
}
