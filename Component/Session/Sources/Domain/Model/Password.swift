/// Evans, *Domain-Driven Design* (2003) — Value Objects; Assertions.
public struct Password: Equatable, Sendable {
    public static let minimumLength = 4

    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var isValid: Bool {
        value.count >= Self.minimumLength
    }
}
