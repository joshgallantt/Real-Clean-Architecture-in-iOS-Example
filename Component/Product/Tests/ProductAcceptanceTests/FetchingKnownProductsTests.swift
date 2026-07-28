import Testing
import Product

/// Screens that remember what a shopper chose remember ids, not products, and ask for
/// the products back when the shopper returns. This is that contract: a known set of
/// ids in, the same products in the same order out. What the ids meant to the screen
/// that stored them — a bag, a wishlist, a recently-viewed list — is not this
/// component's business.
@Suite("Fetching a known set of products")
struct FetchingKnownProductsTests {

    @Test("Products come back in the order they were asked for")
    func keepsTheRequestedOrder() async {
        let shop = Shop()

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products.success?.map(\.title) == [
            "Dolce Shine Eau de",
            "Mascara Lash Princess",
            "Annibale Colombo Sofa"
        ])
    }

    @Test("Asking for no products asks the shop for nothing at all")
    func asksForNothing() async {
        let shop = Shop()

        let products = await shop.products(withIds: [])

        #expect(products.success == [])
        #expect(shop.catalog.requestedPaths.isEmpty)
    }

    @Test("A product delisted since its id was stored drops out, and the rest survive")
    func delistedProductsDropOut() async {
        let shop = Shop()
        shop.catalog.delist(id: 1)

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products.success?.map(\.title) == ["Dolce Shine Eau de", "Annibale Colombo Sofa"])
    }

    @Test("A set larger than a single page comes back in full, in order")
    func fetchesALargeSet() async {
        let items = (1...40).map { CatalogItem(id: $0, title: "Item \($0)", category: "beauty") }
        let shop = Shop(catalog: FakeCatalog(items: items))
        let wanted = Array((1...40).reversed())

        let products = await shop.products(withIds: wanted)

        #expect(products.success?.map(\.id) == wanted)
    }

    @Test("A set whose every product has been delisted is empty, not broken")
    func everyProductDelisted() async {
        let shop = Shop()
        for id in [6, 1, 8] { shop.catalog.delist(id: id) }

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products == .success([]))
    }

    @Test("An unreachable shop is a failure, even though it looks the same as everything being delisted")
    func unreachableIsNotEmpty() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.products(withIds: [6, 1, 8]) == .failure(.networkFailure))
    }

    @Test("One unreachable product fails the set rather than quietly shortening it")
    func oneUnreachableProductFailsTheSet() async {
        let shop = Shop()
        shop.catalog.failRequests(forId: 1)

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products == .failure(.networkFailure))
    }
}
