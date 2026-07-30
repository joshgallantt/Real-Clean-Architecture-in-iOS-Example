import Foundation

/// What a shopper is called, in one place.
///
/// A last name is genuinely optional — plenty of people have one name — and saying so here
/// is the point of the type. Held as two loose strings, that intent is invisible: the model
/// asks for both, the rule quietly only checks one, and the only place the decision is
/// written down is a test. A shopper called Prince gets an account either way; the
/// difference is whether the next person to read the model can tell that was meant.
///
/// Absent rather than blank, so there is one representation of having no last name instead
/// of two that have to be checked for separately.
///
/// Like `Email`, it holds whatever it is given and answers whether that is acceptable, so a
/// half-typed name is representable and a sign-up form can use this type.
public struct PersonName: Equatable, Sendable {
    public let first: String
    public let last: String?

    public init(first: String, last: String?) {
        self.first = first
        self.last = last.flatMap { Self.trimmed($0).isEmpty ? nil : $0 }
    }

    /// A first name is the whole rule. Everything else about a name is the shopper's
    /// business.
    public var isValid: Bool {
        !Self.trimmed(first).isEmpty
    }

    public var full: String {
        [Self.trimmed(first), last.map(Self.trimmed) ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
