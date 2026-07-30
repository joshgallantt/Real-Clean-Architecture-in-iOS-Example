import Foundation

/// Evans, *Domain-Driven Design* (2003) — Making Implicit Concepts Explicit: what counts as a
/// search, and when two searches are the same search, was a rule spread across a text field, a
/// catalog request and a history list — three places free to disagree.
///
/// Evans — Value Objects; Assertions: the rule is stated once, on the thing it is about. Failable
/// rather than lenient, because nothing needs to hold a half-typed search: `nil` means there was
/// none.
public struct SearchTerm: Sendable {
    public let text: String

    public init?(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.text = trimmed
    }
}

extension SearchTerm: Equatable, Hashable {
    public static func == (lhs: SearchTerm, rhs: SearchTerm) -> Bool {
        lhs.text.caseInsensitiveCompare(rhs.text) == .orderedSame
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text.lowercased())
    }
}
