import Foundation
import Product

/// The searches a shopper has run lately, most recent first.
///
/// What "lately" means lives here: running the same search again moves it back to the top
/// rather than listing it twice, and only the last handful are worth keeping. What makes
/// two searches *the same* search, and what makes something a search at all, is
/// `SearchTerm`'s to say — so a blank one cannot get in here, and "Red Dress" cannot sit
/// alongside "red dress", without this having to check either.
public struct SearchHistory: Equatable, Sendable {
    /// Enough to be useful as a shortcut, few enough to stay one glance.
    public static let limit = 10

    public let terms: [SearchTerm]

    public init(terms: [SearchTerm] = []) {
        self.terms = Array(terms.prefix(Self.limit))
    }

    public var isEmpty: Bool { terms.isEmpty }

    /// Searching for something already remembered moves it to the top rather than
    /// repeating it, and the spelling kept is the one the shopper just used.
    public func recording(_ term: SearchTerm) -> SearchHistory {
        SearchHistory(terms: [term] + terms.filter { $0 != term })
    }

    public func cleared() -> SearchHistory {
        SearchHistory()
    }
}
