import Testing
import Money
import Product

@Suite("Shopping the catalog")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: a whole feature wired as the
/// composition root wires it, driven only through the use cases the UI is given. What no layer test
/// can show is that the layers fit together.
///
/// Evans, *Domain-Driven Design* (2003) — Ubiquitous Language: the tests are named in the shopper's
/// words, so a failure reads as a broken journey rather than a broken method.
struct ShoppingTheCatalogTests {
    @Test("A shopper opens the app and sees the first page of products")
    func opensTheApp() async {
        let shop = Shop()

        let firstPage = await shop.browse(page: 0, pageSize: 3)

        #expect(firstPage.success?.map(\.title) == [
            "Mascara Lash Princess",
            "Eyeshadow Palette",
            "Powder Canister"
        ])
    }

    @Test("Scrolling to the end brings the next page, and nothing already seen")
    func scrollsToTheNextPage() async {
        let shop = Shop()

        let firstPage = await shop.browse(page: 0, pageSize: 3)
        let secondPage = await shop.browse(page: 1, pageSize: 3)

        #expect(secondPage.success?.map(\.title) == [
            "Red Lipstick",
            "Calvin Klein CK One",
            "Dolce Shine Eau de"
        ])
        let seen = Set(firstPage.success?.map(\.id) ?? [])
        #expect(seen.isDisjoint(with: Set(secondPage.success?.map(\.id) ?? [])))
    }

    @Test("A shopper picks a category from the list and sees only that category's products")
    func narrowsToACategory() async throws {
        let shop = Shop()

        let categories = await shop.categories()
        #expect(categories.success?.map(\.name) == ["Beauty", "Fragrances", "Furniture"])

        let fragrances = try #require(categories.success?.first { $0.name == "Fragrances" })
        let products = await shop.browse(fragrances)

        #expect(products.success?.map(\.title) == ["Calvin Klein CK One", "Dolce Shine Eau de"])
    }

    @Test("A shopper searches for something the shop stocks and sees the matches")
    func searches() async {
        let shop = Shop()

        let results = await shop.search("Annibale")

        #expect(results.success?.map(\.title) == ["Annibale Colombo Bed", "Annibale Colombo Sofa"])
    }

    @Test("A shopper opens a product from the grid and sees its details")
    func opensAProduct() async {
        let shop = Shop()

        let product = await shop.open(productId: 5)

        #expect(product.success?.title == "Calvin Klein CK One")
        #expect(product.success?.price == Money(amount: 49.99, currency: .usd))
    }

    @Test("A shopper returns to a screen that remembered ids and gets the products back, in order")
    func returnsToASavedSet() async {
        let shop = Shop()

        let products = await shop.products(withIds: [6, 1, 8])

        #expect(products.success?.map(\.title) == [
            "Dolce Shine Eau de",
            "Mascara Lash Princess",
            "Annibale Colombo Sofa"
        ])
    }

    @Test("A shopper sees what the shop can and cannot supply, and which absences are permanent")
    func seesWhatIsAvailable() async throws {
        let shop = Shop(catalog: FakeCatalog(items: [
            CatalogItem(id: 1, title: "In Stock", category: "beauty", stock: 4),
            CatalogItem(id: 2, title: "Back Soon", category: "beauty", stock: 0),
            CatalogItem(id: 3, title: "Gone For Good", category: "beauty", stock: 0, willRestock: false)
        ]))

        let products = try #require(await shop.browse().success)

        #expect(products.map(\.availability) == [
            .inStock(remaining: 4),
            .outOfStock,
            .discontinued
        ])
    }

    @Test("A shopper who cannot reach the shop is told, rather than shown an empty catalog")
    func cannotReachTheShop() async {
        let shop = Shop()
        shop.catalog.goOffline()

        #expect(await shop.browse() == .failure(.unavailable))
    }

    @Test("A shopper who goes offline mid-session sees the failure on their next action, not stale results")
    func goesOfflineMidSession() async {
        let shop = Shop()

        let beforeLosingSignal = await shop.browse(page: 0, pageSize: 3)
        shop.catalog.goOffline()
        let afterLosingSignal = await shop.browse(page: 1, pageSize: 3)

        #expect(beforeLosingSignal.success?.count == 3)
        #expect(afterLosingSignal == .failure(.unavailable))
    }
}
