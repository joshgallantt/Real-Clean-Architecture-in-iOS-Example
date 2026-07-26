import Foundation
import Wishlist

public protocol WishlistStore: Sendable {
    func getItems(forUserKey userKey: String) -> [WishlistItem]
    func setItems(_ items: [WishlistItem], forUserKey userKey: String) async
}

// Reads are synchronous because they happen once per user switch, and seeding the
// repository asynchronously would flash empty hearts on launch. Writes happen on
// every toggle and re-encode the whole list, so they go off the main thread.
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

    public func getItems(forUserKey userKey: String) -> [WishlistItem] {
        if let items = readFile(forUserKey: userKey) {
            return items
        }
        return migrateLegacyItems(forUserKey: userKey)
    }

    public func setItems(_ items: [WishlistItem], forUserKey userKey: String) async {
        let dtos = items.map(WishlistItemDTO.init(from:))
        let directory = self.directory
        let url = url(for: userKey)

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

    // Wishlists written before the move off UserDefaults. Runs at most once per
    // user, on the first read with no file present. Delete this method, its call
    // site, and `legacyDefaults` once the upgrade window has passed.
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
}
