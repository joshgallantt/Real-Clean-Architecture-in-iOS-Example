import Foundation
import Session

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SearchHistoryStore: Sendable {
    func getQueries(for session: Session) -> [String]
    func setQueries(_ queries: [String], for session: Session)
}

public struct UserDefaultsSearchHistoryStore: SearchHistoryStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func getQueries(for session: Session) -> [String] {
        defaults.stringArray(forKey: Self.key(for: session)) ?? []
    }

    public func setQueries(_ queries: [String], for session: Session) {
        defaults.set(queries, forKey: Self.key(for: session))
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place a signed-in id becomes a string.
    private static func key(for session: Session) -> String {
        switch session {
        case .guest: "searchHistory.guest"
        case .authenticated(let user): "searchHistory.\(user.id.rawValue)"
        }
    }
}
