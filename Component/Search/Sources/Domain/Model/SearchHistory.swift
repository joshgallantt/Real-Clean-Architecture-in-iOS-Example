import Foundation

/// The searches a shopper has run lately, most recent first.
///
/// Every rule about what "lately" means lives here: blank searches are not searches,
/// running the same one again moves it back to the top rather than listing it twice,
/// case is not what makes two searches different, and only the last handful are worth
/// keeping. None of that depends on where the list is stored.
public struct SearchHistory: Equatable, Sendable {
    /// Enough to be useful as a shortcut, few enough to stay one glance.
    public static let limit = 10

    public let queries: [String]

    public init(queries: [String] = []) {
        self.queries = Array(queries.prefix(Self.limit))
    }

    public var isEmpty: Bool { queries.isEmpty }

    /// Blank is not a search. Searching for something already remembered moves it to
    /// the top rather than repeating it, and "Red Dress" does not become a second entry
    /// alongside "red dress".
    public func recording(_ query: String) -> SearchHistory {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return self }

        let withoutRepeat = queries.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        return SearchHistory(queries: [trimmed] + withoutRepeat)
    }

    public func cleared() -> SearchHistory {
        SearchHistory()
    }
}
