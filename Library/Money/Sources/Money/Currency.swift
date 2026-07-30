/// Fowler, *PoEAA* (2002) — Money: the unit travels with the amount rather than being assumed by
/// the code that happens to be adding.
///
/// Evans, *Domain-Driven Design* (2003) — Value Objects.
public struct Currency: Equatable, Hashable, Sendable {
    public let code: String

    public let minorUnitsPerMajor: Int

    public init(code: String, minorUnitsPerMajor: Int) {
        self.code = code
        self.minorUnitsPerMajor = minorUnitsPerMajor
    }

    public static let usd = Currency(code: "USD", minorUnitsPerMajor: 100)
}
