import Testing
import Money
import Product

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

    @Test("Looking one up by id gives nothing back either, which is how a list learns it has gone")
    func aListTheShopperAlreadyHoldsIsToldNothing() async {
        let shop = shopThatHasStoppedSellingSomething()

        let products = await shop.products(withIds: [2, 3])

        /// Asked about two, told about one. A bag or a wishlist holding 3 concludes from the
        /// silence that it has been stopped — there is no state to read, because there is no
        /// product to read it from.
        #expect(products.success?.map(\.title) == ["Back Soon"])
    }

    @Test("Something merely out of stock is still sold, and still shown")
    func outOfStockIsNotGone() async {
        let shop = shopThatHasStoppedSellingSomething()

        let backSoon = await shop.browse().success?.first { $0.title == "Back Soon" }

        #expect(backSoon?.availability == .outOfStock)
    }
}
