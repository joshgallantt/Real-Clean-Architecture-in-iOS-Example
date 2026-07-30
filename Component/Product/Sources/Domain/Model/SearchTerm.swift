import Foundation

/// Something a shopper is looking for.
///
/// Every rule about what makes a search a search, and about when two searches are the same
/// search, lives here: surrounding whitespace is not part of what they typed, blank is not
/// a search at all, and case is not what makes two searches different. Spread across a text
/// field, a catalog request and a history list, those rules disagree — a screen can trim
/// before searching while the thing remembering it does not, and then "Red Dress" is
/// searched for but "red dress" is what gets remembered.
///
/// A smart constructor here, unlike `Email`, because nothing needs to hold a half-typed
/// search: the text field holds a `String` and only becomes a term at the moment a shopper
/// commits to it. `nil` means there was no search to run.
public struct SearchTerm: Sendable {
    /// What the shopper typed, minus the whitespace around it. Their capitalisation is
    /// kept — it is theirs to see in their own history.
    public let text: String

    public init?(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.text = trimmed
    }
}

/// Two searches for the same words are the same search however they were capitalised.
extension SearchTerm: Equatable, Hashable {
    public static func == (lhs: SearchTerm, rhs: SearchTerm) -> Bool {
        lhs.text.caseInsensitiveCompare(rhs.text) == .orderedSame
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text.lowercased())
    }
}
