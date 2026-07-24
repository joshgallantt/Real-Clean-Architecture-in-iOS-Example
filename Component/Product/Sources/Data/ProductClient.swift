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
            URLQueryItem(name: "skip", value: String(query.page * query.pageSize)),
        ]

        if let category = query.category {
            path = "products/category/\(category.value)"
        } else if let searchText = query.searchText {
            path = "products/search"
            queryItems.append(URLQueryItem(name: "q", value: searchText))
        } else {
            path = "products"
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
