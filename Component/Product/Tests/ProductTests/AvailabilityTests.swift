import Testing
import Product

/// Whether the shop can supply something, and how much it can supply. One idea with three
/// states, rather than a count plus a flag that only means anything when the count is zero.
@Suite("What the shop can supply")
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
        // The case can be written down, so the question has to be answered rather than
        // assumed away. Nothing that can supply nothing is available.
        #expect(!Availability.inStock(remaining: 0).isAvailable)
    }
}
