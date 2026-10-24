import Testing
import Money
import Product

@Suite("Coming back to a list of things the shopper saved")
/// The bag and the wishlist keep ids, not products. Filling that list back in is where a shop that
/// has moved on since is met, so what a shopper sees when it has is decided here.
struct FillingInASavedListTests {
    @Test("A list of nothing needs nothing from the shop")
    func nothingSaved() async {
        let shop = Shop()

        #expect(await shop.products(withIds: []).success == [])
    }

    @Test("The list comes back in the order the shopper saved it, not the order the shop answered")
    func keepsTheShoppersOrder() async {
        let shop = Shop()

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products.success?.map(\.title) == [
            "Dolce Shine Eau de",
            "Mascara Lash Princess",
            "Annibale Colombo Sofa"
        ])
    }

    @Test("Something delisted since the shopper saved it drops out, and the rest still arrive")
    func delistedDropsOut() async {
        let shop = Shop()

        let products = await shop.products(withIds: [1, 999, 8])

        #expect(products.success?.map(\.title) == ["Mascara Lash Princess", "Annibale Colombo Sofa"])
    }

    @Test("A list of nothing but delisted things is an empty list, not a broken one")
    func everythingDelisted() async {
        let shop = Shop()

        #expect(await shop.products(withIds: [998, 999]).success == [])
    }

    @Test("One product the shopper cannot be told about fails the list rather than quietly shortening it")
    func oneUnreachableFailsTheList() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.products(withIds: [1, 8]) == .failure(.unavailable))
    }

    @Test("A saved list longer than a page comes back in full")
    func longerThanAPage() async {
        let shop = Shop()

        let products = await shop.products(withIds: Array(1...8).reversed())

        #expect(products.success?.map(\.id.rawValue) == Array(1...8).reversed())
    }

    @Test("A list far longer than the shop is asked about at once still comes back whole, and in order")
    func longerThanTheShopIsAskedAtOnce() async {
        let many = (1...60).map { CatalogItem(id: $0, title: "Product \($0)", category: "beauty") }
        let shop = Shop(catalog: FakeCatalog(items: many))

        let wanted = Array((1...60).reversed())
        let products = await shop.products(withIds: wanted)

        #expect(products.success?.map(\.id.rawValue) == wanted)
    }
}
