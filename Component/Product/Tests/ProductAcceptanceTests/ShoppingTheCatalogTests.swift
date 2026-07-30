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

    @Test("Spaces either side of what they typed are not part of what they searched for")
    func searchIgnoresSurroundingSpace() async {
        let shop = Shop()

        let padded = await shop.search("  Annibale  ")

        #expect(padded.success?.map(\.title) == ["Annibale Colombo Bed", "Annibale Colombo Sofa"])
    }

    @Test("Tapping search with nothing typed searches for nothing")
    func searchesForNothing() async {
        let shop = Shop()

        #expect(await shop.search("   ").success == [])
    }

    @Test("A product the shop lists without a brand is still a product")
    func productWithoutABrand() async throws {
        let shop = Shop(catalog: FakeCatalog(items: [
            CatalogItem(id: 1, title: "Annibale Colombo Bed", category: "furniture", brand: nil)
        ]))

        let product = try #require(await shop.open(productId: 1).success)

        #expect(product.title == "Annibale Colombo Bed")
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

    @Test("A shopper sees what the shop can and cannot supply, and which absences are temporary")
    func seesWhatIsAvailable() async throws {
        let shop = Shop(catalog: FakeCatalog(items: [
            CatalogItem(id: 1, title: "In Stock", category: "beauty", stock: 4),
            CatalogItem(id: 2, title: "Back Soon", category: "beauty", stock: 0)
        ]))

        let products = try #require(await shop.browse().success)

        #expect(products.map(\.availability) == [.inStock(remaining: 4), .outOfStock])
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

    @Test(
        "Every way the shop can fail to answer reads the same to a shopper: it is not available",
        arguments: [FakeCatalog.Trouble.noSignal, .shopIsBroken, .answersNonsense]
    )
    func troubleReadsAsUnavailable(_ trouble: FakeCatalog.Trouble) async {
        let shop = Shop()
        shop.catalog.runInto(trouble)

        #expect(await shop.browse() == .failure(.unavailable))
        #expect(await shop.categories() == .failure(.unavailable))
    }

    @Test("A product the shop no longer lists is gone, which is not the same as being unreachable")
    func productIsGone() async {
        let shop = Shop()

        #expect(await shop.open(productId: 999) == .failure(.notFound))

        shop.catalog.goOffline()
        #expect(await shop.open(productId: 1) == .failure(.unavailable))
    }
}

@Suite("What the shop has stopped selling")
/// A shop does not offer what it will not sell again. The one place it is still spoken about is a
/// bag that was filled before it went, which has to be able to say so — see `Component/Bag`.
struct WhatTheShopHasStoppedSellingTests {
    private func shopThatHasStoppedSellingSomething() -> Shop {
        Shop(catalog: FakeCatalog(items: [
            CatalogItem(id: 1, title: "Still Sold", category: "beauty", stock: 4),
            CatalogItem(id: 2, title: "Back Soon", category: "beauty", stock: 0),
            CatalogItem(id: 3, title: "Gone For Good", category: "beauty", stock: 0, willRestock: false)
        ]))
    }

    @Test("It is not on the shelf a shopper is browsing")
    func notWhenBrowsing() async {
        let shop = shopThatHasStoppedSellingSomething()

        #expect(await shop.browse().success?.map(\.title) == ["Still Sold", "Back Soon"])
    }

    @Test("It is not in a category a shopper opens")
    func notInACategory() async throws {
        let shop = shopThatHasStoppedSellingSomething()
        let beauty = try #require(await shop.categories().success?.first { $0.id.rawValue == "beauty" })

        #expect(await shop.browse(beauty).success?.map(\.title) == ["Still Sold", "Back Soon"])
    }

    @Test("It is not among the results when a shopper searches for it by name")
    func notInSearchResults() async {
        let shop = shopThatHasStoppedSellingSomething()

        #expect(await shop.search("Gone For Good").success == [])
    }

    @Test("Its page is gone too — a link to one is not found, not an offer nobody can take")
    func itsPageIsGone() async {
        let shop = shopThatHasStoppedSellingSomething()

        #expect(await shop.open(productId: 3) == .failure(.notFound))
        #expect(await shop.open(productId: 2).success?.title == "Back Soon")
    }

    @Test("A bag or a wishlist filled before it went can still say what it was")
    func aListTheShopperAlreadyHoldsStillKnows() async {
        let shop = shopThatHasStoppedSellingSomething()

        let products = await shop.products(withIds: [3])

        #expect(products.success?.map(\.title) == ["Gone For Good"])
        #expect(products.success?.map(\.availability) == [.discontinued])
    }

    @Test("Something merely out of stock is still sold, and still shown")
    func outOfStockIsNotGone() async {
        let shop = shopThatHasStoppedSellingSomething()

        let backSoon = await shop.browse().success?.first { $0.title == "Back Soon" }

        #expect(backSoon?.availability == .outOfStock)
    }
}

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
