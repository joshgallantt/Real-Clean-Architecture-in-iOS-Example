import Money

/// Evans, *Domain-Driven Design* (2003), Ch. 8 — Domain Events: something a shopper saw or did, said
/// in terms no analytics vendor owns — what it is called, where it happened, what it was about, and
/// whatever else is worth knowing.
///
/// One shape for every event. What tells two apart is the name, and the names are one closed list
/// — see `EventName`: whoever reports a step through the shop builds one of these with a name from
/// that list, and the data layer owns what each vendor calls it.
///
/// It always has a `context`, so an event with nowhere to have happened cannot be built.
public struct TrackingEvent: Equatable, Sendable {
    public let name: EventName
    public let context: TrackingContext

    /// What it was about. Empty when it was about nothing a shopper could pick.
    public let items: [TrackedItem]

    /// Anything else worth knowing, as plain key-value pairs: the element's name, an order's id, what
    /// was searched for. A vendor that calls it something else
    /// renames it, and one that has no use for it leaves it out.
    public let properties: [String: String]

    public init(name: EventName, context: TrackingContext, items: [TrackedItem], properties: [String: String]) {
        self.name = name
        self.context = context
        self.items = items
        self.properties = properties
    }

    /// What the products it is about add up to: each one's price times how many. Nothing when any
    /// item is not a product, or when the prices are in two currencies and could not be added
    /// without inventing a rate — no value is better than a wrong one.
    public var value: Money? {
        var lines: [Money] = []
        for item in items {
            guard case .product(_, let price, let quantity) = item.details else { return nil }
            lines.append(price * quantity)
        }
        guard Set(lines.map(\.currency)).count == 1 else { return nil }
        return Money.total(of: lines)
    }
}
