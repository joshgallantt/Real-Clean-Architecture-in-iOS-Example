/// Opaque identity for a category. The backend's token format — a kebab-case slug today —
/// is not the domain's business, and nothing inward of the data layer reads `rawValue`.
public struct CategoryID: Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
