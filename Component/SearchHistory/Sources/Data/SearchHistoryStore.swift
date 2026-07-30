import Foundation

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SearchHistoryStore: Sendable {
    func getQueries(forUserKey userKey: String) -> [String]
    func setQueries(_ queries: [String], forUserKey userKey: String)
}

public struct UserDefaultsSearchHistoryStore: SearchHistoryStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func getQueries(forUserKey userKey: String) -> [String] {
        defaults.stringArray(forKey: key(for: userKey)) ?? []
    }

    public func setQueries(_ queries: [String], forUserKey userKey: String) {
        defaults.set(queries, forKey: key(for: userKey))
    }

    private func key(for userKey: String) -> String {
        "searchHistory.\(userKey)"
    }
}
