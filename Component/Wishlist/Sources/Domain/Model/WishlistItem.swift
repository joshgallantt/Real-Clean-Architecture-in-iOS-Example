import Foundation
import Product

/// One product a shopper has saved, and when they saved it.
///
/// `productId` says what it refers to. Named for what it is rather than called `id`, because
/// a list of things whose identity is `id: Int` reads the same whether those integers are
/// products, users or line numbers.
public struct WishlistItem: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let dateAdded: Date

    /// A wishlist holds each product once, so the product is what identifies the entry.
    public var id: ProductID { productId }

    public init(productId: ProductID, dateAdded: Date = Date()) {
        self.productId = productId
        self.dateAdded = dateAdded
    }
}
