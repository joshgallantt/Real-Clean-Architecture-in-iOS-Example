import Testing
import Product

/// Every one of these journeys ends with the shopper being told something went wrong.
/// None of them may end with an empty shelf, which the UI cannot tell apart from a
/// shop that genuinely stocks nothing.
@Suite("When the shop is unreachable")
struct WhenTheShopIsUnreachableTests {

    @Test("Browsing offline tells the shopper, rather than showing an empty catalog")
    func browsing() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.browse() == .failure(.networkFailure))
    }

    @Test("Searching offline tells the shopper, rather than showing no matches")
    func searching() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.search("mascara") == .failure(.networkFailure))
    }

    @Test("The category list being unreachable is reported, not shown as no categories")
    func categories() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.categories() == .failure(.networkFailure))
    }

    @Test("Opening a product offline is reported")
    func openingAProduct() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.open(productId: 1) == .failure(.networkFailure))
    }

    @Test("A known set of products that cannot be fetched is reported, rather than appearing empty")
    func fetchingKnownProducts() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.products(withIds: [1, 2]) == .failure(.networkFailure))
    }

    @Test("A shopper who goes offline mid-session sees the failure on their next action, not stale results")
    func goesOfflineMidSession() async {
        let shop = Shop()

        let beforeLosingSignal = await shop.browse(page: 0, pageSize: 3)
        shop.catalog.goOffline()
        let afterLosingSignal = await shop.browse(page: 1, pageSize: 3)

        #expect(beforeLosingSignal.success?.count == 3)
        #expect(afterLosingSignal == .failure(.networkFailure))
    }
}
