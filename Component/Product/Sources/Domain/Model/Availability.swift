/// Evans, *Domain-Driven Design* (2003), Ch. 9 — Making Implicit Concepts Explicit: held as a count
/// plus a will-it-return flag, the flag is meaningless while the count is positive and every caller
/// has to know that to read either. Named as states, the impossible combinations cannot be written
/// down.
///
/// Two cases, not three. A product the shop has stopped selling is not a state it reports — it is a
/// product the shop stops answering for, which the data layer turns into no product at all. Whoever
/// held its id learns it has gone by asking and being given nothing, and there is exactly one way
/// that fact can arrive.
///
/// Evans, Ch. 5 — Value Objects.
public enum Availability: Equatable, Hashable, Sendable {
    case inStock(remaining: Int)

    /// Sold out, and coming back. Worth a bell.
    case outOfStock

    public var isAvailable: Bool {
        remaining > 0
    }

    public var remaining: Int {
        if case .inStock(let remaining) = self { return remaining }
        return 0
    }
}
