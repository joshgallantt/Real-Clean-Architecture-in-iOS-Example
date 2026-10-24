import Foundation
import Testing
@testable import Product

@Suite("CatalogQuery")
struct CatalogQueryTests {
    private let beauty = ProductCategory(id: CategoryID(rawValue: "beauty"), name: "Beauty")

    @Test("Asking for everything asks with no filter")
    func all() {
        #expect(CatalogQuery.all(page: 0, pageSize: 30).filter == .all)
    }

    @Test("A search carries the term it is for")
    func search() throws {
        let term = try #require(SearchTerm("lipstick"))
        #expect(CatalogQuery.search(term, page: 0, pageSize: 30).filter == .search(term))
    }

    @Test("A category asks for that category")
    func category() {
        #expect(CatalogQuery.category(beauty, page: 0, pageSize: 30).filter == .category(beauty))
    }

    @Test("A query keeps the page it was asked for")
    func paging() {
        let query = CatalogQuery.all(page: 2, pageSize: 30)
        #expect(query.page == 2)
        #expect(query.pageSize == 30)
    }

    @Test("The same question asked twice is the same query")
    func equality() {
        #expect(CatalogQuery.all(page: 1, pageSize: 30) == CatalogQuery.all(page: 1, pageSize: 30))
        #expect(CatalogQuery.all(page: 1, pageSize: 30) != CatalogQuery.all(page: 2, pageSize: 30))
    }

    @Test("A search and a category are never the same filter")
    func filtersAreDistinct() throws {
        let term = try #require(SearchTerm("beauty"))
        #expect(CatalogFilter.search(term) != .category(beauty))
        #expect(CatalogFilter.all != .search(term))
    }
}
