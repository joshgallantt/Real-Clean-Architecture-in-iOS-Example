/// What an amount is denominated in, and how many of its smallest units make one of its
/// largest.
///
/// Carried around with every amount rather than assumed, because the assumption is only
/// ever right until it isn't: the day the shop sells in a second currency, adding two
/// amounts that do not belong together stops being a silently wrong total and becomes a
/// caught mistake.
public struct Currency: Equatable, Hashable, Sendable {
    /// ISO 4217, e.g. `USD`.
    public let code: String

    /// 100 for a currency with cents, 1 for one without.
    public let minorUnitsPerMajor: Int

    public init(code: String, minorUnitsPerMajor: Int) {
        self.code = code
        self.minorUnitsPerMajor = minorUnitsPerMajor
    }

    public static let usd = Currency(code: "USD", minorUnitsPerMajor: 100)
}
