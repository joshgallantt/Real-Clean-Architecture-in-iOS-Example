import Foundation
import Bag

public protocol BagStore: Sendable {
    func getBag(forUserKey userKey: String) -> Bag
    func setBag(_ bag: Bag, forUserKey userKey: String) async
}

// Reads are synchronous because they happen once per user switch, and seeding the
// repository asynchronously would flash an empty bag on launch. Writes happen on
// every change and re-encode the whole bag, so they go off the main thread.
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

    public func getBag(forUserKey userKey: String) -> Bag {
        guard
            let data = try? Data(contentsOf: url(for: userKey)),
            let dto = try? JSONDecoder().decode(BagDTO.self, from: data)
        else {
            return Bag()
        }
        return dto.toDomain()
    }

    public func setBag(_ bag: Bag, forUserKey userKey: String) async {
        let dto = BagDTO(from: bag)
        let directory = self.directory
        let url = url(for: userKey)

        await Task.detached(priority: .utility) {
            Self.write(dto, to: url, in: directory)
        }.value
    }

    private static func write(_ dto: BagDTO, to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dto) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func url(for userKey: String) -> URL {
        directory.appending(path: "\(userKey).json", directoryHint: .notDirectory)
    }
}
