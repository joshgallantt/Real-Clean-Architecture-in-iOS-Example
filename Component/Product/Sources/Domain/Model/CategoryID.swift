/// Evans, *Domain-Driven Design* (2003) — Value Objects. Fowler, *PoEAA* (2002) — Identity Field.
public struct CategoryID: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
