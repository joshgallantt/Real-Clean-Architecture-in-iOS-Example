/// Evans, *Domain-Driven Design* (2003) — Entities.
public struct ProductCategory: Equatable, Hashable, Sendable, Identifiable {
    public let id: CategoryID
    public let name: String

    public init(id: CategoryID, name: String) {
        self.id = id
        self.name = name
    }
}
