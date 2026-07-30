/// Evans, *Domain-Driven Design* (2003) — Aggregates: referenced by identity across contexts.
/// Fowler, *PoEAA* (2002) — Identity Field.
public struct UserID: Equatable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
