import Foundation
import Bag

public protocol BagStore: Sendable {
    func getBag(for owner: BagOwner) -> (bag: Bag, changes: BagChanges)
    func setBag(_ bag: Bag, changes: BagChanges, for owner: BagOwner) async
}

// Reads are synchronous because they happen once per owner switch, and seeding the
// repository asynchronously would flash an empty bag on launch. Writes happen on every
// change and re-encode everything, so they go off the main thread.
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

    public func getBag(for owner: BagOwner) -> (bag: Bag, changes: BagChanges) {
        guard
            let data = try? Data(contentsOf: url(for: owner)),
            let dto = try? JSONDecoder().decode(BagDTO.self, from: data)
        else {
            return (Bag(), BagChanges())
        }
        return dto.toDomain()
    }

    public func setBag(_ bag: Bag, changes: BagChanges, for owner: BagOwner) async {
        let dto = BagDTO(bag: bag, changes: changes)
        let directory = self.directory
        let url = url(for: owner)

        await Task.detached(priority: .utility) {
            Self.write(dto, to: url, in: directory)
        }.value
    }

    private static func write(_ dto: BagDTO, to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dto) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func url(for owner: BagOwner) -> URL {
        directory.appending(path: "\(Self.filename(for: owner)).json", directoryHint: .notDirectory)
    }

    /// What a bag is filed under. The only place an owner turns back into a string, and the
    /// spellings are the ones already on disk so bags kept by earlier builds still load.
    private static func filename(for owner: BagOwner) -> String {
        switch owner {
        case .guest: "guest"
        case .shopper(let id): String(id.rawValue)
        }
    }
}
