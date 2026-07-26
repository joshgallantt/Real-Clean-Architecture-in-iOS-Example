import XCTest
@testable import Product
@testable import ProductData

final class ProductTests: XCTestCase {
    func test_getProductsByIds_preservesRequestedOrder() async {
        let repository = DefaultProductRepository(client: StubProductClient(failing: []))

        let result = await repository.getProducts(ids: [3, 1, 2])

        XCTAssertEqual(try result.get().map(\.id), [3, 1, 2])
    }

    func test_getProductsByIds_fetchesConcurrently() async {
        let client = StubProductClient(failing: [])
        let repository = DefaultProductRepository(client: client)

        _ = await repository.getProducts(ids: Array(1...30))

        // Serial fetching would never overlap; the bounded window should.
        let maxConcurrent = client.maxConcurrent
        XCTAssertGreaterThan(maxConcurrent, 1)
        XCTAssertLessThanOrEqual(maxConcurrent, 6)
    }

    func test_getProductsByIds_dropsIndividualFailures() async {
        let repository = DefaultProductRepository(client: StubProductClient(failing: [2]))

        let result = await repository.getProducts(ids: [1, 2, 3])

        XCTAssertEqual(try result.get().map(\.id), [1, 3])
    }

    func test_getProductsByIds_failsWhenWholeBatchFails() async {
        let repository = DefaultProductRepository(client: StubProductClient(failing: [1, 2]))

        let result = await repository.getProducts(ids: [1, 2])

        XCTAssertEqual(result, .failure(.networkFailure))
    }

    func test_getProductsByIds_shortCircuitsOnEmptyInput() async {
        let client = StubProductClient(failing: [])
        let repository = DefaultProductRepository(client: client)

        let result = await repository.getProducts(ids: [])

        XCTAssertEqual(try result.get(), [])
        let requestCount = client.requestCount
        XCTAssertEqual(requestCount, 0)
    }
}

private struct StubError: Error {}

// A lock rather than an actor: actor isolation would force ProductDTO to be
// Sendable purely to satisfy this stub, and nothing in production returns a DTO
// across an isolation boundary.
private final class StubProductClient: ProductClient, @unchecked Sendable {
    private let failing: Set<Int>
    private let lock = NSLock()
    private var inFlight = 0
    private var _maxConcurrent = 0
    private var _requestCount = 0

    init(failing: Set<Int>) {
        self.failing = failing
    }

    var maxConcurrent: Int { lock.withLock { _maxConcurrent } }
    var requestCount: Int { lock.withLock { _requestCount } }

    func fetchProducts(query: ProductQuery) async throws -> [ProductDTO] { [] }

    func fetchCategories() async throws -> [ProductCategoryDTO] { [] }

    func fetchProduct(id: Int) async throws -> ProductDTO {
        lock.withLock {
            _requestCount += 1
            inFlight += 1
            _maxConcurrent = max(_maxConcurrent, inFlight)
        }
        defer { lock.withLock { inFlight -= 1 } }

        try await Task.sleep(for: .milliseconds(10))

        guard !failing.contains(id) else { throw StubError() }
        return try Self.makeDTO(id: id)
    }

    private static func makeDTO(id: Int) throws -> ProductDTO {
        let json = """
        {
          "id": \(id), "title": "Product \(id)", "description": "", "category": "misc",
          "price": 1, "discountPercentage": 0, "rating": 0, "stock": 1,
          "brand": null, "thumbnail": "", "images": []
        }
        """
        return try JSONDecoder().decode(ProductDTO.self, from: Data(json.utf8))
    }
}
