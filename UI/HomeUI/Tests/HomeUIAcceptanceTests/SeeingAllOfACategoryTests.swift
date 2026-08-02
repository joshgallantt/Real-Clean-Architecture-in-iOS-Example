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
    func viewAllOpensItsOwnCategory() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        await shopper.opensHome()

        shopper.tapsViewAll(for: .fragrances)

        #expect(shopper.navigation.openedCatalogs == [.category(.fragrances)])
    }

    // HomeFeedCarousels-14: Every carousel shown offers its own working View All button — not
    // only the first one, and not only the one a shopper happens to tap.
    @Test("Every carousel shown offers its own working View All button")
    func everyCarouselOffersViewAll() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        shopper.sells(.fragrances, products(101...105, category: "fragrances"))
        shopper.sells(.furniture, products(201...206, category: "furniture"))
        await shopper.opensHome()

        for category in [ProductCategory.beauty, .fragrances, .furniture] {
            shopper.tapsViewAll(for: category)
        }

        #expect(shopper.navigation.openedCatalogs == [.category(.beauty), .category(.fragrances), .category(.furniture)])
    }

    // HomeFeedCarousels-15: Tapping View All does not change what Home itself is showing, so
    // coming back to it shows exactly what was left — same categories, same products, same order.
    @Test("Tapping View All does not change what Home itself is showing")
    func viewAllDoesNotChangeHome() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...5, category: "beauty"))
        await shopper.opensHome()
        let before = shopper.carouselsShown

        shopper.tapsViewAll(for: .beauty)

        #expect(shopper.carouselsShown == before)
    }
}
