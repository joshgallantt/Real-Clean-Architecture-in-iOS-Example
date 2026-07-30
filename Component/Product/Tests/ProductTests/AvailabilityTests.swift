import Testing
import Product

@Suite("What the shop can supply")
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the domain is tested with no
/// repository, no store and no simulator in the room. Anything here that needed one would not be a
/// domain rule.
struct AvailabilityTests {
    @Test("Something in stock is available, and says how many")
    func inStock() {
        let availability = Availability.inStock(remaining: 4)

        #expect(availability.isAvailable)
        #expect(availability.remaining == 4)
    }

    @Test("Something out of stock can supply none of itself")
    func outOfStock() {
        #expect(!Availability.outOfStock.isAvailable)
        #expect(Availability.outOfStock.remaining == 0)
    }

    @Test("Something discontinued can supply none of itself either")
    func discontinued() {
        #expect(!Availability.discontinued.isAvailable)
        #expect(Availability.discontinued.remaining == 0)
    }

    @Test("In stock with none left is not available, whatever it calls itself")
    func inStockOfNone() {
        #expect(!Availability.inStock(remaining: 0).isAvailable)
    }
}
