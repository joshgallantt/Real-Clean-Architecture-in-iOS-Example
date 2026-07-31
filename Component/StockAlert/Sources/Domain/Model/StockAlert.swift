import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: holds another aggregate by identity alone.
/// What the product is called and what it costs are the catalog's to answer, and both will have
/// moved on by the time the shopper hears anything — which is the entire point of asking.
///
/// Evans — Ubiquitous Language: a shopper does not subscribe or register an interest. They ask to
/// be told when something is back, and this is the record of that ask.
public struct StockAlert: Equatable, Sendable, Identifiable {
    public let productId: ProductID
    public let dateAsked: Date

    /// When the shop said it was back. Nothing while the shopper is still waiting.
    ///
    /// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: an ask has
    /// a moment it is answered, and nothing recorded it. Every alert ever made stayed indefinitely,
    /// so a list of what somebody was waiting for filled up with things that had already arrived.
    public let backSince: Date?

    public var id: ProductID { productId }

    /// Still waiting to hear. The bell is about this, not about whether an ask was ever made — a
    /// shopper who has been told is not waiting any more.
    public var isWaiting: Bool { backSince == nil }

    public init(productId: ProductID, dateAsked: Date = Date(), backSince: Date? = nil) {
        self.productId = productId
        self.dateAsked = dateAsked
        self.backSince = backSince
    }

    public func markedBack(at moment: Date) -> StockAlert {
        StockAlert(productId: productId, dateAsked: dateAsked, backSince: moment)
    }
}
