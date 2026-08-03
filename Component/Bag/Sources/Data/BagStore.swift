import Foundation
import Bag
import Session

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving.
public protocol BagStore: Sendable {
    func getBag(for session: Session) -> (bag: Bag, notices: Notices)
    func setBag(_ bag: Bag, notices: Notices, for session: Session) async
}

public struct FileBagStore: BagStore, @unchecked Sendable {
    private let directory: URL

    public init(directory: URL = FileBagStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
        return base.appending(path: "Bag", directoryHint: .isDirectory)
    }

    public func getBag(for session: Session) -> (bag: Bag, notices: Notices) {
        guard
            let data = try? Data(contentsOf: url(for: session)),
            let dto = try? JSONDecoder().decode(BagDTO.self, from: data)
        else {
            return (Bag(), Notices())
        }
        return dto.toDomain()
    }

    public func setBag(_ bag: Bag, notices: Notices, for session: Session) async {
        let dto = BagDTO(bag: bag, notices: notices)
        let directory = self.directory
        let url = url(for: session)

        await Task.detached(priority: .utility) {
            Self.write(dto, to: url, in: directory)
        }.value
    }

    private static func write(_ dto: BagDTO, to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dto) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
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
