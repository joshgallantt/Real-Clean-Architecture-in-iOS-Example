import Foundation
import Testing
@testable import Product

/// Martin, *The Clean Coder* (2011), Ch. 8 — Unit Tests: the acceptance suite says browsing broke;
/// these say which rule did. Aimed at the value objects, which is the most stable seam a component
/// has — a rule stated on a type survives the wiring above it being rearranged.
@Suite("Availability")
struct AvailabilityTests {
    @Test("Stock on the shelf is available")
    func inStock() {
        #expect(Availability.inStock(remaining: 3).isAvailable)
    }

    @Test("One is still available")
    func lastOne() {
        #expect(Availability.inStock(remaining: 1).isAvailable)
    }

    @Test("Sold out is not")
    func outOfStock() {
        #expect(Availability.outOfStock.isAvailable == false)
    }

    @Test("A count of none is not available either, whatever case it arrived in")
    func inStockOfNone() {
        #expect(Availability.inStock(remaining: 0).isAvailable == false)
    }

    @Test("What is left is the count, and nothing is left when sold out")
    func remaining() {
        #expect(Availability.inStock(remaining: 4).remaining == 4)
        #expect(Availability.outOfStock.remaining == 0)
    }

    @Test("Two of the same state are the same")
    func equality() {
        #expect(Availability.inStock(remaining: 2) == .inStock(remaining: 2))
        #expect(Availability.inStock(remaining: 2) != .inStock(remaining: 3))
        #expect(Availability.inStock(remaining: 0) != .outOfStock)
    }
}

@Suite("SearchTerm")
struct SearchTermTests {
    @Test("An ordinary search is a search")
    func ordinary() {
        #expect(SearchTerm("lipstick")?.text == "lipstick")
    }

    @Test("Surrounding whitespace is not part of what was searched for")
    func trims() {
        #expect(SearchTerm("  lipstick  ")?.text == "lipstick")
    }

    @Test("Nothing typed is not a search")
    func empty() {
        #expect(SearchTerm("") == nil)
    }

    @Test("Whitespace alone is not a search")
    func whitespaceOnly() {
        #expect(SearchTerm("   ") == nil)
        #expect(SearchTerm("\n\t") == nil)
    }

    @Test("The same word in different case is the same search")
    func caseInsensitiveEquality() {
        #expect(SearchTerm("Lipstick") == SearchTerm("lipstick"))
        #expect(SearchTerm("LIPSTICK") == SearchTerm("lipstick"))
    }

    @Test("Two searches that differ by spacing alone are the same search")
    func whitespaceInsensitiveEquality() {
        #expect(SearchTerm(" lipstick") == SearchTerm("lipstick "))
    }

    @Test("Different words are different searches")
    func differentTerms() {
        #expect(SearchTerm("lipstick") != SearchTerm("mascara"))
    }

    @Test("Two searches that are equal hash alike, so a set keeps one")
    func hashing() {
        let terms = Set([SearchTerm("Lipstick"), SearchTerm("lipstick"), SearchTerm("mascara")])
        #expect(terms.count == 2)
    }
}

@Suite("Identifiers")
struct IdentifierTests {
    @Test("Two product ids with the same number are the same product")
    func productIdEquality() {
        #expect(ProductID(rawValue: 7) == ProductID(rawValue: 7))
        #expect(ProductID(rawValue: 7) != ProductID(rawValue: 8))
    }

    @Test("A product id keeps its number")
    func productIdRawValue() {
        #expect(ProductID(rawValue: 7).rawValue == 7)
    }

    @Test("Product ids hash by their number, so a set keeps one of each")
    func productIdHashing() {
        #expect(Set([ProductID(rawValue: 1), ProductID(rawValue: 1), ProductID(rawValue: 2)]).count == 2)
    }

    @Test("Two category ids with the same name are the same category")
    func categoryIdEquality() {
        #expect(CategoryID(rawValue: "beauty") == CategoryID(rawValue: "beauty"))
        #expect(CategoryID(rawValue: "beauty") != CategoryID(rawValue: "Beauty"))
    }

    @Test("A category id keeps its name")
    func categoryIdRawValue() {
        #expect(CategoryID(rawValue: "beauty").rawValue == "beauty")
    }
}

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
