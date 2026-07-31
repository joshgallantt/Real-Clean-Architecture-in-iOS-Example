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


    public var id: ProductID { productId }


    public init(productId: ProductID, dateAsked: Date = Date()) {
        self.productId = productId
        self.dateAsked = dateAsked
    }
}
