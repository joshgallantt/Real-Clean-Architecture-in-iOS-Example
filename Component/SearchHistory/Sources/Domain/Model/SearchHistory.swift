import Foundation
import Product

/// Evans, *Domain-Driven Design* (2003) — Aggregates: the root, owning what "lately" means — the
/// same search again moves to the top rather than repeating, and only the last handful are kept.
///
/// Evans — Conceptual Contours: what makes something a search, and what makes two searches the
/// same, belongs to `SearchTerm`. This cannot restate those rules and so cannot drift from them.
///
/// Evans — Side-Effect-Free Functions.
public struct SearchHistory: Equatable, Sendable {
    public static let limit = 10

    public let terms: [SearchTerm]

    public init(terms: [SearchTerm] = []) {
        self.terms = Array(terms.prefix(Self.limit))
    }

    public var isEmpty: Bool { terms.isEmpty }

    public func recording(_ term: SearchTerm) -> SearchHistory {
        SearchHistory(terms: [term] + terms.filter { $0 != term })
    }

    public func cleared() -> SearchHistory {
        SearchHistory()
    }
}
