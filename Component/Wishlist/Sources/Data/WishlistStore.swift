import Foundation
import Session
import Wishlist

/// A wishlist belongs to a signed-in shopper. `nil` is nobody signed in, which has no
/// wishlist to read and nowhere to write one — a guest cannot save anything in the first
/// place, so there is no such file and never was.
public protocol WishlistStore: Sendable {
    func getItems(for owner: UserID?) -> [WishlistItem]
    func setItems(_ items: [WishlistItem], for owner: UserID?) async
}

// Reads are synchronous because they happen once per owner switch, and seeding the
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

    /// What a wishlist is filed under. The only place an owner turns back into a string, and
    /// the spelling is the one already on disk so lists kept by earlier builds still load.
    private static func filename(for owner: UserID?) -> String? {
        owner.map { String($0.rawValue) }
    }
}
