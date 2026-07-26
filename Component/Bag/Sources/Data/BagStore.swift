import Foundation
import Bag

public protocol BagStore: Sendable {
    func getItems(forUserKey userKey: String) -> [BagItem]
    func setItems(_ items: [BagItem], forUserKey userKey: String) async
}

// Reads are synchronous because they happen once per user switch, and seeding the
// repository asynchronously would flash an empty bag on launch. Writes happen on
// every mutation and re-encode the whole list, so they go off the main thread.
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

    public func getItems(forUserKey userKey: String) -> [BagItem] {
        guard
            let data = try? Data(contentsOf: url(for: userKey)),
            let dtos = try? JSONDecoder().decode([BagItemDTO].self, from: data)
        else {
            return []
        }
        return dtos.map { $0.toDomain() }
    }

    public func setItems(_ items: [BagItem], forUserKey userKey: String) async {
        let dtos = items.map(BagItemDTO.init(from:))
        let directory = self.directory
        let url = url(for: userKey)

        await Task.detached(priority: .utility) {
            Self.write(dtos, to: url, in: directory)
        }.value
    }

    private static func write(_ dtos: [BagItemDTO], to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dtos) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func url(for userKey: String) -> URL {
        directory.appending(path: "\(userKey).json", directoryHint: .notDirectory)
    }
}
