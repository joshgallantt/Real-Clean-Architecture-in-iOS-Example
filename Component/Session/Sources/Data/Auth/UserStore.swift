import Foundation

public protocol UserStore: Sendable {
    func find(email: String) -> StoredUser?
    func save(_ user: StoredUser)
}

public struct UserDefaultsUserStore: UserStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "users.database"

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func find(email: String) -> StoredUser? {
        all()[email.lowercased()]
    }

    public func save(_ user: StoredUser) {
        var users = all()
        users[user.email.lowercased()] = user
        guard let data = try? JSONEncoder().encode(users) else { return }
        defaults.set(data, forKey: key)
    }

    private func all() -> [String: StoredUser] {
        guard
            let data = defaults.data(forKey: key),
            let users = try? JSONDecoder().decode([String: StoredUser].self, from: data)
        else {
            return [:]
        }
        return users
    }
}
