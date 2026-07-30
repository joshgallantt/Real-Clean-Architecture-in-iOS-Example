import Foundation
import Networking

/// Fowler, *PoEAA* (2002) — Gateway: the fake is the transport, so the client, the repository, the
/// DTO decoding and the use cases are all the real implementations. A journey that passes here is
/// one the app can complete.
final class FakeCatalog: HTTPClient, @unchecked Sendable {
    /// The ways a shop can fail to answer, as a shopper would meet them: no signal, the shop
    /// itself broken, or an answer the app cannot make sense of.
    enum Trouble {
        case noSignal
        case shopIsBroken
        case answersNonsense
    }

    private let lock = NSLock()
    private let items: [CatalogItem]
    private let categories: [CategoryPayload]
    private var trouble: Trouble?

    init(
        items: [CatalogItem] = CatalogItem.sampleCatalog,
        categories: [CategoryPayload] = CategoryPayload.sampleCategories
    ) {
        self.items = items
        self.categories = categories
    }

    func goOffline() { runInto(.noSignal) }

    func runInto(_ trouble: Trouble) { lock.withLock { self.trouble = trouble } }

    func get<T: Decodable>(_ url: URL) async throws -> T {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let path = components?.path ?? ""
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )

        switch lock.withLock({ trouble }) {
        case .noSignal: throw HTTPClientError.transport
        case .shopIsBroken: throw HTTPClientError.server(statusCode: 500)
        case .answersNonsense: return try JSONDecoder().decode(T.self, from: Data("{}".utf8))
        case .none: break
        }

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
