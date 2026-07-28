import Testing
import Product

@Suite("Searching the catalog")
struct SearchingTheCatalogTests {

    @Test("A shopper searches for something the shop stocks and sees the matches")
    func findsWhatTheyAreLookingFor() async {
        let shop = Shop()

        let results = await shop.search("Annibale")

        #expect(results.success?.map(\.title) == ["Annibale Colombo Bed", "Annibale Colombo Sofa"])
    }

    @Test("A search that matches nothing is an empty shelf, not an error")
    func findsNothing() async {
        let shop = Shop()

        let results = await shop.search("snowboard")

        #expect(results.success == [])
    }

    @Test("A shopper refining their search sees the narrower result, not the broader one")
    func refinesTheirSearch() async {
        let shop = Shop()

        let broad = await shop.search("Annibale")
        let refined = await shop.search("Annibale Colombo Sofa")

        #expect(broad.success?.count == 2)
        #expect(refined.success?.map(\.title) == ["Annibale Colombo Sofa"])
    }

    @Test("Search text with punctuation and spaces reaches the shop intact")
    func searchesWithAwkwardText() async {
        let shop = Shop()

        let results = await shop.search("Dolce Shine Eau de")

        #expect(results.success?.map(\.title) == ["Dolce Shine Eau de"])
    }

    @Test("Search results are paged the same way browsing is")
    func pagesThroughResults() async {
        let shop = Shop()

        let firstPage = await shop.search("a", page: 0, pageSize: 2)
        let secondPage = await shop.search("a", page: 1, pageSize: 2)

        #expect(firstPage.success?.count == 2)
        #expect(secondPage.success?.count == 2)
        let seen = Set(firstPage.success?.map(\.id) ?? [])
        #expect(seen.isDisjoint(with: Set(secondPage.success?.map(\.id) ?? [])))
    }
}
