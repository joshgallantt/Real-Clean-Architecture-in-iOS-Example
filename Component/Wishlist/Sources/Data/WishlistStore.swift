import Foundation
import Session
import Wishlist

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol WishlistStore: Sendable {
    func getItems(for owner: UserID?) -> [WishlistItem]
    func setItems(_ items: [WishlistItem], for owner: UserID?) async
}

public struct FileWishlistStore: WishlistStore, @unchecked Sendable {
    private let directory: URL
    private let legacyDefaults: UserDefaults

    public init(
        directory: URL = FileWishlistStore.defaultDirectory,
        legacyDefaults: UserDefaults = .standard
    ) {
        self.directory = directory
        self.legacyDefaults = legacyDefaults
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
        return base.appending(path: "Wishlist", directoryHint: .isDirectory)
    }

    public func getItems(for owner: UserID?) -> [WishlistItem] {
        guard let key = Self.filename(for: owner) else { return [] }
        if let items = readFile(forUserKey: key) {
            return items
        }
        return migrateLegacyItems(forUserKey: key)
    }

    public func setItems(_ items: [WishlistItem], for owner: UserID?) async {
        guard let key = Self.filename(for: owner) else { return }
        let dtos = items.map(WishlistItemDTO.init(from:))
        let directory = self.directory
        let url = url(for: key)

        await Task.detached(priority: .utility) {
            Self.write(dtos, to: url, in: directory)
        }.value
    }

    private func readFile(forUserKey userKey: String) -> [WishlistItem]? {
        guard
            let data = try? Data(contentsOf: url(for: userKey)),
            let dtos = try? JSONDecoder().decode([WishlistItemDTO].self, from: data)
        else {
            return nil
        }
        return dtos.map { $0.toDomain() }
    }

    private func migrateLegacyItems(forUserKey userKey: String) -> [WishlistItem] {
        let legacyKey = "wishlist.\(userKey)"
        defer { legacyDefaults.removeObject(forKey: legacyKey) }

        guard
            let data = legacyDefaults.data(forKey: legacyKey),
            let dtos = try? JSONDecoder().decode([WishlistItemDTO].self, from: data)
        else {
            return []
        }

        Self.write(dtos, to: url(for: userKey), in: directory)
        return dtos.map { $0.toDomain() }
    }

    private static func write(_ dtos: [WishlistItemDTO], to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dtos) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func url(for userKey: String) -> URL {
        directory.appending(path: "\(userKey).json", directoryHint: .notDirectory)
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place an owner becomes a string.
    private static func filename(for owner: UserID?) -> String? {
        owner.map { String($0.rawValue) }
    }
}
