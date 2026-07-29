/// What counts as a password, in one place.
///
/// Like `Email`, it holds whatever it is given and answers whether that is acceptable,
/// so a half-typed password is representable.
public struct Password: Equatable, Sendable {
    /// Short enough not to annoy, long enough to be worth having. One number, and any
    /// length rule beyond this, is the shop's policy to add here — not the sign-up
    /// screen's to invent.
    public static let minimumLength = 4

    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var isValid: Bool {
        value.count >= Self.minimumLength
    }
}
