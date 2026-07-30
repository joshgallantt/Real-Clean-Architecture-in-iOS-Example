import Foundation

/// Fowler, *PoEAA* (2002) — Money: a quantity is inseparable from its currency, and is counted in
/// the smallest whole unit so arithmetic is exact rather than approximate.
///
/// Evans, *Domain-Driven Design* (2003) — Value Objects: identified by value, immutable, freely
/// shared. Evans — Closure of Operations: `+` and `*` return `Money`, so amounts compose without
/// leaving the type.
public struct Money: Equatable, Hashable, Sendable {
    public let minorUnits: Int
    public let currency: Currency

    public init(minorUnits: Int, currency: Currency) {
        self.minorUnits = minorUnits
        self.currency = currency
    }

    public init(amount: Decimal, currency: Currency) {
        var scaled = amount * Decimal(currency.minorUnitsPerMajor)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        self.init(
            minorUnits: NSDecimalNumber(decimal: rounded).intValue,
            currency: currency
        )
    }

    public var amount: Decimal {
        Decimal(minorUnits) / Decimal(currency.minorUnitsPerMajor)
    }

    public func formatted() -> String {
        amount.formatted(.currency(code: currency.code))
    }
}

// MARK: - Arithmetic

extension Money {
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot add \(rhs.currency.code) to \(lhs.currency.code)"
        )
        return Money(minorUnits: lhs.minorUnits + rhs.minorUnits, currency: lhs.currency)
    }

    public static func * (lhs: Money, count: Int) -> Money {
        Money(minorUnits: lhs.minorUnits * count, currency: lhs.currency)
    }
}

extension Money: Comparable {
    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot compare \(lhs.currency.code) with \(rhs.currency.code)"
        )
        return lhs.minorUnits < rhs.minorUnits
    }
}

/// Fowler, *PoEAA* (2002) — Money: nothing at all for an empty sequence, because there is no
/// currency in it to name an amount in.
extension Sequence where Element == Money {
    public func total() -> Money? {
        reduce(nil) { running, next in
            running.map { $0 + next } ?? next
        }
    }
}
