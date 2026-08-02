import Foundation
import Testing
import Product

@MainActor
@Suite("The feed groups products by category")
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: named for what a shopper's Home
/// draws — carousels, not one list mixing every category together.
struct TheHomeFeedTests {
    // HomeFeed-01: A feed groups a shopper's carousel by category, not as one list mixing every
    // category together.
    @Test("A feed groups a shopper's carousel by category, not as one list mixing every category together")
    func groupsByCategoryNotAList() async {
        let shopper = Shopper()
        shopper.sells(.beauty, products(1...6, category: "beauty"))

        await shopper.opensHome()

        #expect(shopper.carouselsShown.map(\.category.name) == ["Beauty"])
    }
}
