import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 10 — Interface Segregation Principle: the bag reads
/// three things about a product. Taking `Product` would make it depend on seven more it never
/// reads, each a reason to recompile and a reason it could only ever be satisfied by the catalog.
///
/// Evans, *Domain-Driven Design* (2003) — Bounded Context; Anticorruption Layer: the translated
/// form at the boundary between Catalog and Bag. `ProductID` and `Availability` are imported
/// unchanged rather than restated, because identity and availability mean the same thing in both
/// contexts and a second definition would be a second answer.
///
/// Evans — Value Objects.
public struct ShopSays: Equatable, Sendable {
    public let productId: ProductID
    public let price: Money
    public let availability: Availability

    public init(productId: ProductID, price: Money, availability: Availability) {
        self.productId = productId
        self.price = price
        self.availability = availability
    }
}
