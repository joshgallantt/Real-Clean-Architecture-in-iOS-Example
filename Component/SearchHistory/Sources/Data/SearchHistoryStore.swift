import Foundation
import Session

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SearchHistoryStore: Sendable {
    func getQueries(for owner: Owner) -> [String]
    func setQueries(_ queries: [String], for owner: Owner)
}

public struct UserDefaultsSearchHistoryStore: SearchHistoryStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func getQueries(for owner: Owner) -> [String] {
        defaults.stringArray(forKey: Self.key(for: owner)) ?? []
    }

    public func setQueries(_ queries: [String], for owner: Owner) {
        defaults.set(queries, forKey: Self.key(for: owner))
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place an owner becomes a string.
    private static func key(for owner: Owner) -> String {
        switch owner {
        case .guest: "searchHistory.guest"
        case .signedIn(let id): "searchHistory.\(id.rawValue)"
        }
    }
}
