/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: held as a count plus a
/// will-it-return flag, the flag is meaningless while the count is positive and every caller has to
/// know that to read either. Named as states, the impossible combinations cannot be written down.
///
/// Evans — Value Objects.
public enum Availability: Equatable, Hashable, Sendable {
    case inStock(remaining: Int)

    case outOfStock

    case discontinued

    public var isAvailable: Bool {
        remaining > 0
    }

    public var remaining: Int {
        if case .inStock(let remaining) = self { return remaining }
        return 0
    }
}
