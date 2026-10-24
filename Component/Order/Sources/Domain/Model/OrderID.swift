import Foundation

/// Fowler, *PoEAA* (2002), Ch. 12 — Identity Field. Evans, *Domain-Driven Design* (2003), Ch. 5 —
/// Entities: identity is the one part of an order another context may hold, which is exactly why it
/// is worth a type rather than a `String` that could be a product id, a name or a payment reference.
public struct OrderID: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: UUID().uuidString)
    }
}
