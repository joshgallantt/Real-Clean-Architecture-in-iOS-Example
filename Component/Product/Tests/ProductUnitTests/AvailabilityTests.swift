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
