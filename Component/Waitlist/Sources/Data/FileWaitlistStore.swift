import Foundation
import Session
import Waitlist

public struct FileWaitlistStore: WaitlistStore, @unchecked Sendable {
    private let directory: URL
    private let legacyDirectory: URL

    public init(
        directory: URL = FileWaitlistStore.defaultDirectory,
        legacyDirectory: URL = FileWaitlistStore.defaultLegacyDirectory
    ) {
        self.directory = directory
        self.legacyDirectory = legacyDirectory
    }

    public static var defaultDirectory: URL {
        applicationSupport.appending(path: "Waitlist", directoryHint: .isDirectory)
    }

    /// Where the waitlist was kept when it was called stock alerts.
    public static var defaultLegacyDirectory: URL {
        applicationSupport.appending(path: "StockAlerts", directoryHint: .isDirectory)
    }

    private static var applicationSupport: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
    }

    public func getItems(for owner: UserID?) -> [WaitlistItem] {
        guard let key = Self.filename(for: owner) else { return [] }
        if let items = readFile(forUserKey: key) {
            return items
        }
        return migrateLegacyItems(forUserKey: key)
    }

    public func setItems(_ items: [WaitlistItem], for owner: UserID?) async throws {
        guard let key = Self.filename(for: owner) else { return }
        let dtos = items.map(WaitlistItemDTO.init(from:))
        let directory = self.directory
        let url = url(for: key, in: directory)

        try await Task.detached(priority: .utility) {
            try Self.write(dtos, to: url, in: directory)
        }.value
    }

    private func readFile(forUserKey userKey: String) -> [WaitlistItem]? {
        guard
            let data = try? Data(contentsOf: url(for: userKey, in: directory)),
            let dtos = try? JSONDecoder().decode([WaitlistItemDTO].self, from: data)
        else {
            return nil
        }
        return dtos.map { $0.toDomain() }
    }

    private func migrateLegacyItems(forUserKey userKey: String) -> [WaitlistItem] {
        let legacyURL = url(for: userKey, in: legacyDirectory)
        guard
            let data = try? Data(contentsOf: legacyURL),
            let legacy = try? JSONDecoder().decode([LegacyStockAlertDTO].self, from: data)
        else {
            return []
        }
        let items = legacy.map { $0.toDomain() }

        // A migration that cannot be written is still a list that can be read. The shopper gets
        // their waitlist; the copy forward is retried on their next visit, so the old file is only
        // removed once the new one exists.
        if (try? Self.write(items.map(WaitlistItemDTO.init(from:)), to: url(for: userKey, in: directory), in: directory)) != nil {
            try? FileManager.default.removeItem(at: legacyURL)
        }
        return items
    }

    private static func write(_ dtos: [WaitlistItemDTO], to url: URL, in directory: URL) throws {
        let data = try JSONEncoder().encode(dtos)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func url(for userKey: String, in directory: URL) -> URL {
        directory.appending(path: "\(userKey).json", directoryHint: .notDirectory)
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place an owner becomes a string.
    private static func filename(for owner: UserID?) -> String? {
        owner.map { String($0.rawValue) }
    }
}
