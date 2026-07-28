import Testing
import Product

/// The shop is reachable but wrong: a field renamed, a bad deploy, a partial payload.
/// A half-built product must never reach the screen, and neither must a silently
/// shortened list.
///
/// The domain draws only one distinction — a product that is definitively gone, versus
/// products it could not get — so a catalog talking nonsense lands on the same side as
/// a catalog that cannot be reached. Both leave the shopper with nothing to show and
/// a retry as the only sensible next step.
@Suite("When the shop misdescribes its products")
struct WhenTheShopMisdescribesItselfTests {

    @Test("A catalog page the app cannot make sense of is reported, not shown half-built")
    func browsing() async {
        let shop = Shop()
        shop.catalog.serveMalformedProducts()

        #expect(await shop.browse() == .failure(.networkFailure))
    }

    @Test("Search results the app cannot make sense of are reported")
    func searching() async {
        let shop = Shop()
        shop.catalog.serveMalformedProducts()

        #expect(await shop.search("mascara") == .failure(.networkFailure))
    }

    @Test("A category list with no identities to browse by is reported")
    func categories() async {
        let shop = Shop()
        shop.catalog.serveMalformedProducts()

        #expect(await shop.categories() == .failure(.networkFailure))
    }

    @Test("A product the app cannot make sense of cannot be opened")
    func openingAProduct() async {
        let shop = Shop()
        shop.catalog.serveMalformedProducts()

        #expect(await shop.open(productId: 1) == .failure(.networkFailure))
    }

    @Test("A set of products the app cannot make sense of is reported rather than appearing empty")
    func fetchingKnownProducts() async {
        let shop = Shop()
        shop.catalog.serveMalformedProducts()

        #expect(await shop.products(withIds: [1, 2]) == .failure(.networkFailure))
    }
}
