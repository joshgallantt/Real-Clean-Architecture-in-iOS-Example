import Foundation
import Session
import Settings

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol SettingsStore: Sendable {
    func getSettings(for session: Session) -> Settings

    /// Throws when the change could not be kept. What went wrong is the store's business; that it
    /// did not happen is the domain's.
    func setSettings(_ settings: Settings, for session: Session) async throws
}

public struct FileSettingsStore: SettingsStore, @unchecked Sendable {
    private let directory: URL

    public init(directory: URL = FileSettingsStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
        return base.appending(path: "Settings", directoryHint: .isDirectory)
    }

    public func getSettings(for session: Session) -> Settings {
        guard
            let data = try? Data(contentsOf: url(for: session)),
            let dto = try? JSONDecoder().decode(SettingsDTO.self, from: data)
        else {
            return Settings()
        }
        return dto.toDomain()
    }

    public func setSettings(_ settings: Settings, for session: Session) async throws {
        let dto = SettingsDTO(settings: settings)
        let directory = self.directory
        let url = url(for: session)

        try await Task.detached(priority: .utility) {
            try Self.write(dto, to: url, in: directory)
        }.value
    }

    private static func write(_ dto: SettingsDTO, to url: URL, in directory: URL) throws {
        let data = try JSONEncoder().encode(dto)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func url(for session: Session) -> URL {
        directory.appending(path: "\(Self.filename(for: session)).json", directoryHint: .notDirectory)
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is
    /// filed under is the storage layer's business. The only place a signed-in id becomes a string.
    private static func filename(for session: Session) -> String {
        switch session {
        case .guest: "guest"
        case .authenticated(let user): String(user.id.rawValue)
        }
    }
}
