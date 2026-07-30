import Foundation

/// An amount of money, held in whole smallest-units of its currency.
///
/// Not `Double`. A price like 9.99 has no exact binary representation, so a total built by
/// adding them drifts — 9.99 + 49.99 comes out as 59.980000000000004 — and two amounts that
/// should be equal compare unequal. That matters here beyond tidiness: whether the shopper
/// is *told* a price moved is decided by comparing two amounts, and drift turns "nothing
/// happened" into a notice about nothing.
///
/// Counting in minor units makes the arithmetic exact, and pairing the count with its
/// currency means an amount always knows what it is denominated in.
public struct Money: Equatable, Hashable, Sendable {
    public let minorUnits: Int
    public let currency: Currency

    public init(minorUnits: Int, currency: Currency) {
        self.minorUnits = minorUnits
        self.currency = currency
    }

    /// Builds an amount from a major-unit figure, e.g. `9.99` dollars.
    ///
    /// Rounds to the nearest minor unit, which is the only sensible reading of a price that
    /// arrives with more precision than the currency has.
    public init(amount: Decimal, currency: Currency) {
        var scaled = amount * Decimal(currency.minorUnitsPerMajor)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        self.init(
            minorUnits: NSDecimalNumber(decimal: rounded).intValue,
            currency: currency
        )
    }

    /// The amount as a major-unit figure, for formatting. Exact, because it is derived from
    /// the integer count rather than the other way round.
    public var amount: Decimal {
        Decimal(minorUnits) / Decimal(currency.minorUnitsPerMajor)
    }

    public func formatted() -> String {
        amount.formatted(.currency(code: currency.code))
    }
}

// MARK: - Arithmetic

/// Amounts in different currencies are not comparable and do not add. There is no right
/// answer to give in that case, and returning a wrong one quietly is worse than stopping:
/// a total is either correct or it is misinformation.
extension Money {
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot add \(rhs.currency.code) to \(lhs.currency.code)"
        )
        return Money(minorUnits: lhs.minorUnits + rhs.minorUnits, currency: lhs.currency)
    }

    /// Times a count, which is what a line in a bag needs and the only multiplication that
    /// means anything: money times money is not money.
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

extension Sequence where Element == Money {
    /// The total, or nothing at all when there is nothing to total. An empty collection is
    /// not worth zero of any particular currency — there is no currency in it to name.
    public func total() -> Money? {
        reduce(nil) { running, next in
            running.map { $0 + next } ?? next
        }
    }
}
