/// Evans, *Domain-Driven Design* (2003) — Aggregates: other aggregates are referenced only by
/// identity, so this is the one part of a product a bag or a wishlist may hold.
///
/// Evans — Value Objects. Fowler, *PoEAA* (2002) — Identity Field: the format the backend mints is
/// the data layer's business, not the domain's.
public struct ProductID: Equatable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
