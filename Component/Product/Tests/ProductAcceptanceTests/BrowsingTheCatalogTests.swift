import Testing
import Product

@Suite("Browsing the catalog")
struct BrowsingTheCatalogTests {

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

    @Test("Scrolling to the end brings the next page, and nothing the shopper has already seen")
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
        let next = Set(secondPage.success?.map(\.id) ?? [])
        #expect(seen.isDisjoint(with: next))
    }

    @Test("Scrolling past the last product yields an empty page rather than an error")
    func scrollsPastTheEnd() async {
        let shop = Shop()

        let beyondTheEnd = await shop.browse(page: 9, pageSize: 30)

        #expect(beyondTheEnd.success == [])
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

    @Test("A shopper opens a product from the grid and sees its details")
    func opensAProduct() async {
        let shop = Shop()

        let product = await shop.open(productId: 5)

        #expect(product.success?.title == "Calvin Klein CK One")
        #expect(product.success?.price == 49.99)
        #expect(product.success?.category == CategoryID(rawValue: "fragrances"))
    }

    @Test("A product the shop no longer sells is reported as gone, not as a connection problem")
    func opensADelistedProduct() async {
        let shop = Shop()
        shop.catalog.delist(id: 5)

        #expect(await shop.open(productId: 5) == .failure(.notFound))
    }

    @Test("A product listed without a brand still reaches the shopper, with no brand shown")
    func brandlessProductsStillAppear() async {
        let shop = Shop()

        let bed = await shop.open(productId: 7)

        #expect(bed.success?.title == "Annibale Colombo Bed")
        #expect(bed.success?.brand == "")
    }
}
