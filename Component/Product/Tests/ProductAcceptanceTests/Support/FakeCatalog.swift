import Foundation
import Networking

/// A stand-in for the shop's backend, seeded with a small catalog and speaking the
/// same JSON the real one does. It is the only thing faked in these tests: the client,
/// the repository, the DTO decoding and the use cases are all the real implementations,
/// so a journey that passes here is a journey the app can actually complete.
final class FakeCatalog: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [CatalogItem]
    private var categories: [CategoryPayload]
    private var isOffline = false
    private var isMalformed = false
    private var unreachableIds: Set<Int> = []
    private var _requestedPaths: [String] = []

    var requestedPaths: [String] { lock.withLock { _requestedPaths } }

    init(
        items: [CatalogItem] = CatalogItem.sampleCatalog,
        categories: [CategoryPayload] = CategoryPayload.sampleCategories
    ) {
        self.items = items
        self.categories = categories
    }

    /// The shopper loses connectivity.
    func goOffline() { lock.withLock { isOffline = true } }

    /// The shop starts describing its products incompletely — a deploy gone wrong, a
    /// field renamed. The shopper must never be shown a half-built product.
    func serveMalformedProducts() { lock.withLock { isMalformed = true } }

    /// The shop stops selling something the shopper has already seen or bagged.
    func delist(id: Int) { lock.withLock { items.removeAll { $0.id == id } } }

    /// One product becomes unreachable while the rest of the shop stays up — a flaky
    /// connection, a request that times out. Not the same as the product being gone.
    func failRequests(forId id: Int) { lock.withLock { unreachableIds.insert(id) } }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        let state = lock.withLock { () -> (offline: Bool, malformed: Bool, unreachable: Set<Int>, items: [CatalogItem], categories: [CategoryPayload]) in
            _requestedPaths.append(path)
            return (isOffline, isMalformed, unreachableIds, self.items, self.categories)
        }

        if state.offline { throw HTTPClientError.transport }

        if let id = Int(path.dropFirst("/products/".count)), state.unreachable.contains(id) {
            throw HTTPClientError.transport
        }

        let data = state.malformed
            ? Self.malformedResponse(path: path)
            : try Self.respond(path: path, query: query, items: state.items, categories: state.categories)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPClientError.decoding
        }
    }

    func post<Body: Encodable, T: Decodable>(_ url: URL, body: Body) async throws -> T {
        throw HTTPClientError.server(statusCode: 405)
    }

    private static func respond(
        path: String,
        query: [String: String],
        items: [CatalogItem],
        categories: [CategoryPayload]
    ) throws -> Data {
        let encoder = JSONEncoder()

        if path == "/products/categories" {
            return try encoder.encode(categories)
        }

        if path.hasPrefix("/products/category/") {
            let slug = String(path.dropFirst("/products/category/".count))
            return try encoder.encode(page(items.filter { $0.category == slug }, query))
        }

        if path == "/products/search" {
            let text = query["q"] ?? ""
            let matches = items.filter { $0.title.localizedCaseInsensitiveContains(text) }
            return try encoder.encode(page(matches, query))
        }

        if path == "/products" {
            return try encoder.encode(page(items, query))
        }

        if let id = Int(path.replacingOccurrences(of: "/products/", with: "")) {
            guard let item = items.first(where: { $0.id == id }) else {
                throw HTTPClientError.server(statusCode: 404)
            }
            return try encoder.encode(item)
        }

        throw HTTPClientError.server(statusCode: 404)
    }

    /// Products with no price and categories with no identity: syntactically valid
    /// JSON that the domain cannot be built from.
    private static func malformedResponse(path: String) -> Data {
        if path == "/products/categories" {
            return Data(#"[{"name": "Beauty"}]"#.utf8)
        }
        if path.hasPrefix("/products/") && Int(path.dropFirst("/products/".count)) != nil {
            return Data(#"{"id": 1, "title": "Mascara Lash Princess"}"#.utf8)
        }
        return Data(#"{"products": [{"id": 1, "title": "Mascara Lash Princess"}], "total": 1, "skip": 0, "limit": 30}"#.utf8)
    }

    private static func page(_ items: [CatalogItem], _ query: [String: String]) -> PagePayload {
        let limit = Int(query["limit"] ?? "") ?? items.count
        let skip = Int(query["skip"] ?? "") ?? 0
        let window = Array(items.dropFirst(skip).prefix(limit))
        return PagePayload(products: window, total: items.count, skip: skip, limit: limit)
    }
}

struct PagePayload: Encodable {
    let products: [CatalogItem]
    let total: Int
    let skip: Int
    let limit: Int
}

struct CategoryPayload: Encodable {
    let slug: String
    let name: String

    static let sampleCategories = [
        CategoryPayload(slug: "beauty", name: "Beauty"),
        CategoryPayload(slug: "fragrances", name: "Fragrances"),
        CategoryPayload(slug: "furniture", name: "Furniture")
    ]
}
