import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: holds another aggregate by identity alone.
/// What the product is called and what it costs are the catalog's to answer, and both will have
/// moved on by the time the shopper hears anything — which is the entire point of waiting.
public struct WaitlistItem: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let dateAdded: Date

    public var id: ProductID { productId }

    public init(productId: ProductID, dateAdded: Date = Date()) {
        self.productId = productId
        self.dateAdded = dateAdded
    }
}
