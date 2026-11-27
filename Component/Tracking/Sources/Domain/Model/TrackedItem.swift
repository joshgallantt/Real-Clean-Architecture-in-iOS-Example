import Money

/// What an element was about. Every item has an id and a name — a report needs both — and is
/// either something on the shelf or something that is not: a category, a past search, an order.
/// Only the first has a category, a price and a quantity, so only the first can carry them.
public struct TrackedItem: Equatable, Hashable, Sendable {
    public enum Details: Equatable, Hashable, Sendable {
        case content
        case product(category: String, price: Money, quantity: Int)
    }

    public let id: String
    public let name: String
    public let details: Details

    private init(id: String, name: String, details: Details) {
        self.id = id
        self.name = name
        self.details = details
    }

    /// Something on the shelf. The price is the one the shopper agreed to, not today's, and the
    /// quantity is how many the event is about.
    public static func product(id: String, name: String, category: String, price: Money, quantity: Int) -> TrackedItem {
        TrackedItem(id: id, name: name, details: .product(category: category, price: price, quantity: quantity))
    }

    /// Something a shopper can pick that is not on the shelf.
    public static func content(id: String, name: String) -> TrackedItem {
        TrackedItem(id: id, name: name, details: .content)
    }
}
