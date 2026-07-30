import Foundation
import Networking
import Product

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol ProductClient: Sendable {
    func fetchProducts(query: CatalogQuery) async throws -> [ProductDTO]
    func fetchProduct(id: ProductID) async throws -> ProductDTO
    func fetchCategories() async throws -> [ProductCategoryDTO]
}

public struct DummyJSONProductClient: ProductClient {
    private let httpClient: HTTPClient
    private let baseURL = URL(string: "https://dummyjson.com")!

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchProducts(query: CatalogQuery) async throws -> [ProductDTO] {
        let path: String
        var queryItems = [
            URLQueryItem(name: "limit", value: String(query.pageSize)),
            URLQueryItem(name: "skip", value: String(query.page * query.pageSize))
        ]

        switch query.filter {
        case .all:
            path = "products"
        case .search(let term):
            path = "products/search"
            queryItems.append(URLQueryItem(name: "q", value: term.text))
        case .category(let category):
            path = "products/category/\(category.id.rawValue)"
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        let response: ProductListResponseDTO = try await httpClient.get(components.url!)
        return response.products
    }

    public func fetchProduct(id: ProductID) async throws -> ProductDTO {
        try await httpClient.get(baseURL.appendingPathComponent("products/\(id.rawValue)"))
    }

    public func fetchCategories() async throws -> [ProductCategoryDTO] {
        try await httpClient.get(baseURL.appendingPathComponent("products/categories"))
    }
}
