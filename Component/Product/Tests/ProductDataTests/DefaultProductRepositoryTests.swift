import Foundation
import Testing
import Money
import Networking
import Product
@testable import ProductData

/// The repository under test, wired to the real client over a stubbed transport. The
/// URL the catalog is asked for, the JSON it answers with, and the domain models that
/// come out the other side are all genuine — only the network is not.
@Suite("The product catalog")
struct DefaultProductRepositoryTests {

    private func makeRepository() -> (DefaultProductRepository, StubHTTPClient) {
        let transport = StubHTTPClient()
        return (DefaultProductRepository(client: DummyJSONProductClient(httpClient: transport)), transport)
    }

    private func id(_ value: Int) -> ProductID { ProductID(rawValue: value) }

    private func term(_ text: String) -> SearchTerm { SearchTerm(text)! }

    // MARK: - Browsing the catalog

    @Test("Browsing everything reads the unfiltered collection, since the catalog has no 'all' category")
    func browsingEverything() async throws {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.map(\.title) == ["Mascara Lash Princess"])
        #expect(try #require(transport.lastRequest).requestPath == "/products")
    }

    @Test("A search asks the search endpoint and carries the shopper's text")
    func searching() async throws {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/search", query: ["q": "red dress"], returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .search(term("red dress"), page: 0, pageSize: 30))

        #expect(result.success?.count == 1)
        #expect(try #require(transport.lastRequest).requestQuery["q"] == "red dress")
    }

    @Test("A search carries the words alone, with the whitespace around them already gone")
    func searchingIsTrimmedBeforeItLeaves() async throws {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/search", query: ["q": "red dress"], returning: Self.pageJSON)

        _ = await repository.getProducts(matching: .search(term("  red dress  "), page: 0, pageSize: 30))

        #expect(try #require(transport.lastRequest).requestQuery["q"] == "red dress")
    }

    @Test("Browsing a category addresses it by its token, never by its display name")
    func browsingACategory() async throws {
        let (repository, transport) = makeRepository()
        let category = ProductCategory(id: CategoryID(rawValue: "home-decoration"), name: "Home Decoration")
        transport.stub(path: "/products/category/home-decoration", returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .category(category, page: 0, pageSize: 30))

        #expect(result.success?.count == 1)
        #expect(try #require(transport.lastRequest).requestPath == "/products/category/home-decoration")
    }

    @Test("Each page is asked for as a skip of whole pages",
          arguments: [(0, 30, "0", "30"), (1, 30, "30", "30"), (3, 20, "60", "20")])
    func paging(page: Int, pageSize: Int, skip: String, limit: String) async throws {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON)

        _ = await repository.getProducts(matching: .all(page: page, pageSize: pageSize))

        let request = try #require(transport.lastRequest)
        #expect(request.requestQuery["skip"] == skip)
        #expect(request.requestQuery["limit"] == limit)
    }

    @Test("A page yields its products, not its counters")
    func unwrapsThePage() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.map(\.id) == [id(1)])
        #expect(result.success?.first?.category == CategoryID(rawValue: "beauty"))
    }

    // MARK: - Prices

    @Test("A price becomes an exact amount in the shop's currency")
    func priceBecomesMoney() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.first?.price == Money(minorUnits: 999, currency: .usd))
    }

    // MARK: - Availability

    @Test("Stock on the wire becomes how many the shop can supply")
    func stockBecomesAvailability() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON)

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.first?.availability == .inStock(remaining: 5))
    }

    @Test("A catalog that says nothing about restocking is taken to mean it will")
    func restockingIsAssumed() async {
        let (repository, transport) = makeRepository()
        transport.stub(
            path: "/products",
            returning: Self.pageJSON.replacingOccurrences(of: #""stock": 5"#, with: #""stock": 0"#)
        )

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        // DummyJSON has no such field. Assuming the optimistic answer keeps the offer to
        // wait available; assuming the other would hide it everywhere, permanently.
        #expect(result.success?.first?.availability == .outOfStock)
    }

    @Test("A catalog that says something is gone for good is believed")
    func goneForGood() async {
        let (repository, transport) = makeRepository()
        transport.stub(
            path: "/products",
            returning: Self.pageJSON.replacingOccurrences(of: #""stock": 5"#, with: #""stock": 0, "willRestock": false"#)
        )

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.first?.availability == .discontinued)
    }

    @Test("A product listed without a brand is still a product")
    func brandlessProducts() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: Self.pageJSON(brand: "null"))

        let result = await repository.getProducts(matching: .all(page: 0, pageSize: 30))

        #expect(result.success?.first?.brand == "")
    }

    // MARK: - When the shop does not answer

    @Test("A catalog that cannot be reached is unavailable, not an empty catalog")
    func browsingWhenUnreachable() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", failingWith: HTTPClientError.transport)

        #expect(await repository.getProducts(matching: .all(page: 0, pageSize: 30)) == .failure(.unavailable))
    }

    @Test("A catalog the app cannot read is unavailable, not a half-built page")
    func browsingUnreadablePayload() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", returning: #"{"products": [{"id": 1}], "total": 1, "skip": 0, "limit": 30}"#)

        #expect(await repository.getProducts(matching: .all(page: 0, pageSize: 30)) == .failure(.unavailable))
    }

    @Test("A catalog that answers with an error is unavailable")
    func browsingServerError() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products", failingWith: HTTPClientError.server(statusCode: 500))

        #expect(await repository.getProducts(matching: .all(page: 0, pageSize: 30)) == .failure(.unavailable))
    }

    // MARK: - Opening one product

    @Test("Opening a product asks for it by id")
    func openingAProduct() async throws {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/42", returning: Self.productJSON(id: 42))

        let result = await repository.getProduct(id: id(42))

        #expect(result.success?.id == id(42))
        #expect(try #require(transport.lastRequest).requestPath == "/products/42")
    }

    @Test("A product the catalog no longer lists is gone, not a connection problem")
    func openingADelistedProduct() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/42", failingWith: HTTPClientError.server(statusCode: 404))

        #expect(await repository.getProduct(id: id(42)) == .failure(.notFound))
    }

    @Test("A product the app could not reach is a connection problem, not a product that is gone")
    func openingAnUnreachableProduct() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/42", failingWith: HTTPClientError.transport)

        #expect(await repository.getProduct(id: id(42)) == .failure(.unavailable))
    }

    // MARK: - Listing categories

    @Test("A category is identified by its slug and named for display")
    func listingCategories() async throws {
        let (repository, transport) = makeRepository()
        transport.stub(
            path: "/products/categories",
            returning: #"[{"slug": "home-decoration", "name": "Home Decoration"}]"#
        )

        let result = await repository.getCategories()

        #expect(result.success == [
            ProductCategory(id: CategoryID(rawValue: "home-decoration"), name: "Home Decoration")
        ])
        #expect(try #require(transport.lastRequest).requestPath == "/products/categories")
    }

    @Test("A category list with no identities to browse by is unavailable")
    func listingUnreadableCategories() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/categories", returning: #"[{"name": "Beauty"}]"#)

        #expect(await repository.getCategories() == .failure(.unavailable))
    }

    // MARK: - Looking up a known set of ids

    @Test("Asking for no products asks the catalog nothing")
    func emptySet() async {
        let (repository, transport) = makeRepository()

        #expect(await repository.getProducts(ids: []) == .success([]))
        #expect(transport.requestedURLs.isEmpty)
    }

    @Test("Products come back in the order they were asked for, not the order they arrived")
    func setKeepsRequestedOrder() async {
        let (repository, transport) = makeRepository()
        for value in [1, 2, 3] { transport.stub(path: "/products/\(value)", returning: Self.productJSON(id: value)) }

        let result = await repository.getProducts(ids: [id(3), id(1), id(2)])

        #expect(result.success?.map(\.id) == [id(3), id(1), id(2)])
    }

    @Test("A product delisted since its id was stored drops out, and the rest survive")
    func delistedProductDropsOut() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/1", returning: Self.productJSON(id: 1))
        transport.stub(path: "/products/2", failingWith: HTTPClientError.server(statusCode: 404))
        transport.stub(path: "/products/3", returning: Self.productJSON(id: 3))

        let result = await repository.getProducts(ids: [id(1), id(2), id(3)])

        #expect(result.success?.map(\.id) == [id(1), id(3)])
    }

    @Test("A set of nothing but delisted products is empty, not broken")
    func everyProductDelisted() async {
        let (repository, transport) = makeRepository()
        for value in [1, 2] {
            transport.stub(path: "/products/\(value)", failingWith: HTTPClientError.server(statusCode: 404))
        }

        #expect(await repository.getProducts(ids: [id(1), id(2)]) == .success([]))
    }

    @Test("One unreachable product fails the set rather than quietly shortening it")
    func oneUnreachableProductFailsTheSet() async {
        let (repository, transport) = makeRepository()
        transport.stub(path: "/products/1", returning: Self.productJSON(id: 1))
        transport.stub(path: "/products/2", failingWith: HTTPClientError.transport)

        #expect(await repository.getProducts(ids: [id(1), id(2)]) == .failure(.unavailable))
    }

    @Test("A set larger than one page is fetched in full, in order")
    func largeSet() async {
        let (repository, transport) = makeRepository()
        let values = Array(1...40)
        for value in values { transport.stub(path: "/products/\(value)", returning: Self.productJSON(id: value)) }

        let result = await repository.getProducts(ids: values.reversed().map(id))

        #expect(result.success?.map(\.id) == values.reversed().map(id))
    }
}

private extension DefaultProductRepositoryTests {
    /// Carries `discountPercentage` because the real catalog does. The DTO ignores it on
    /// purpose, and this is what proves a field the domain declines to model does not
    /// break the parse.
    static func productJSON(id: Int = 1, brand: String = "\"Essence\"") -> String {
        """
        {
            "id": \(id),
            "title": "Mascara Lash Princess",
            "description": "A volumising mascara.",
            "category": "beauty",
            "price": 9.99,
            "discountPercentage": 7.17,
            "rating": 4.94,
            "stock": 5,
            "brand": \(brand),
            "thumbnail": "https://cdn.example.com/1/thumbnail.png",
            "images": ["https://cdn.example.com/1/1.png"]
        }
        """
    }

    static func pageJSON(brand: String = "\"Essence\"") -> String {
        """
        {"products": [\(productJSON(brand: brand))], "total": 1, "skip": 0, "limit": 30}
        """
    }

    static var pageJSON: String { pageJSON() }
}

extension Result {
    var success: Success? { try? get() }
}
