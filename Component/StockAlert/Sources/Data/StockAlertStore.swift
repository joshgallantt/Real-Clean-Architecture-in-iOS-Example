import Foundation
import Session
import StockAlert

/// Fowler, *PoEAA* (2002) — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving. Today a file on the device; the day a shopper is to
/// be told on more than one, a request — and nothing inward changes.
public protocol StockAlertStore: Sendable {
    func getAlerts(for owner: UserID?) -> [StockAlert]

    /// Throws when the ask could not be kept. What went wrong is the store's business; that it did
    /// not happen is the domain's.
    func setAlerts(_ alerts: [StockAlert], for owner: UserID?) async throws
}

public struct FileStockAlertStore: StockAlertStore, @unchecked Sendable {
    private let directory: URL

    public init(directory: URL = FileStockAlertStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
        return base.appending(path: "StockAlerts", directoryHint: .isDirectory)
    }

    public func getAlerts(for owner: UserID?) -> [StockAlert] {
        guard
            let key = Self.filename(for: owner),
            let data = try? Data(contentsOf: url(for: key)),
            let dtos = try? JSONDecoder().decode([StockAlertDTO].self, from: data)
        else {
            return []
        }
        return dtos.map { $0.toDomain() }
    }

    public func setAlerts(_ alerts: [StockAlert], for owner: UserID?) async throws {
        guard let key = Self.filename(for: owner) else { return }
        let dtos = alerts.map(StockAlertDTO.init(from:))
        let directory = self.directory
        let url = url(for: key)

        try await Task.detached(priority: .utility) {
            let data = try JSONEncoder().encode(dtos)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        }.value
    }

    private func url(for key: String) -> URL {
        directory.appending(path: "\(key).json", directoryHint: .notDirectory)
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place an owner becomes a string.
    private static func filename(for owner: UserID?) -> String? {
        owner.map { String($0.rawValue) }
    }
}
