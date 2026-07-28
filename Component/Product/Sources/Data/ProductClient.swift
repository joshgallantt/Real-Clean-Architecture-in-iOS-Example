import Foundation
import Networking
import Product

public protocol ProductClient: Sendable {
    func fetchProducts(query: ProductQuery) async throws -> [ProductDTO]
    func fetchProduct(id: Int) async throws -> ProductDTO
    func fetchCategories() async throws -> [ProductCategoryDTO]
}

public struct DummyJSONProductClient: ProductClient {
    private let httpClient: HTTPClient
    private let baseURL = URL(string: "https://dummyjson.com")!

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchProducts(query: ProductQuery) async throws -> [ProductDTO] {
        let path: String
        var queryItems = [
            URLQueryItem(name: "limit", value: String(query.pageSize)),
            URLQueryItem(name: "skip", value: String(query.page * query.pageSize))
        ]

        // DummyJSON exposes no "all products" category, so `.all` is served by the
        // unfiltered collection. That gap is this client's problem, not the domain's.
        switch query.filter {
        case .all:
            path = "products"
        case .search(let text):
            path = "products/search"
            queryItems.append(URLQueryItem(name: "q", value: text))
        case .category(let category):
            path = "products/category/\(category.id.rawValue)"
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        let response: ProductListResponseDTO = try await httpClient.get(components.url!)
        return response.products
    }

    public func fetchProduct(id: Int) async throws -> ProductDTO {
        try await httpClient.get(baseURL.appendingPathComponent("products/\(id)"))
    }

    public func fetchCategories() async throws -> [ProductCategoryDTO] {
        try await httpClient.get(baseURL.appendingPathComponent("products/categories"))
    }
}
