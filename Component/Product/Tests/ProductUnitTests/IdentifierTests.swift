import Foundation
import Testing
@testable import Product

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
