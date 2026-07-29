import Foundation
import Networking

/// A stand-in for the shop's backend, seeded with a small catalog and speaking the
/// same JSON the real one does. It is the only thing faked in these tests: the client,
/// the repository, the DTO decoding and the use cases are all the real implementations,
/// so a journey that passes here is a journey the app can actually complete.
///
/// It answers correctly or not at all. Every way a real backend can misbehave — a 404,
/// a 500, a payload with a field missing — is stubbed request by request in
/// ProductDataTests, where a failure names the layer that broke.
final class FakeCatalog: HTTPClient, @unchecked Sendable {
    private let lock = NSLock()
    private let items: [CatalogItem]
    private let categories: [CategoryPayload]
    private var isOffline = false

    init(
        items: [CatalogItem] = CatalogItem.sampleCatalog,
        categories: [CategoryPayload] = CategoryPayload.sampleCategories
    ) {
        self.items = items
        self.categories = categories
    }

    /// The shopper loses connectivity.
    func goOffline() { lock.withLock { isOffline = true } }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        if lock.withLock({ isOffline }) { throw HTTPClientError.transport }

        let data = try Self.respond(path: path, query: query, items: items, categories: categories)
        return try JSONDecoder().decode(T.self, from: data)
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
