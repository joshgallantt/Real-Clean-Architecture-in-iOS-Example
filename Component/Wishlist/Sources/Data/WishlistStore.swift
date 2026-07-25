import Foundation
import Wishlist

public protocol WishlistStore: Sendable {
    func getItems(forUserKey userKey: String) -> [WishlistItem]
    func setItems(_ items: [WishlistItem], forUserKey userKey: String)
}

public struct UserDefaultsWishlistStore: WishlistStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public func getItems(forUserKey userKey: String) -> [WishlistItem] {
        guard
            let data = defaults.data(forKey: key(for: userKey)),
            let dtos = try? JSONDecoder().decode([WishlistItemDTO].self, from: data)
        else {
            return []
        }
        return dtos.map { $0.toDomain() }
    }

    public func setItems(_ items: [WishlistItem], forUserKey userKey: String) {
        let dtos = items.map(WishlistItemDTO.init(from:))
        guard let data = try? JSONEncoder().encode(dtos) else { return }
        defaults.set(data, forKey: key(for: userKey))
    }

    private func key(for userKey: String) -> String {
        "wishlist.\(userKey)"
    }
}
