import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: holds another aggregate by identity alone.
///
/// Evans — Ubiquitous Language: named `productId`, because a list of things whose identity is `id:
/// Int` reads the same whether those integers are products, users or line numbers.
public struct WishlistItem: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let dateAdded: Date

    public var id: ProductID { productId }

    public init(productId: ProductID, dateAdded: Date = Date()) {
        self.productId = productId
        self.dateAdded = dateAdded
    }
}
