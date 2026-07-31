import Foundation
import Order
import Session

/// Fowler, *PoEAA* (2002), Ch. 18 — Gateway: wraps one external system behind a domain-shaped call.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the outermost ring,
/// replaceable without anything inward moving. Today a file on the device; the day orders come back
/// from a server, a request — and nothing inward changes.
public protocol OrderStore: Sendable {
    func getOrders(for owner: UserID?) -> Orders
    func setOrders(_ orders: Orders, for owner: UserID?) async
}

public struct FileOrderStore: OrderStore, @unchecked Sendable {
    private let directory: URL

    public init(directory: URL = FileOrderStore.defaultDirectory) {
        self.directory = directory
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL.temporaryDirectory
        return base.appending(path: "Orders", directoryHint: .isDirectory)
    }

    /// An unreadable file gives back no orders rather than throwing. Losing sight of what was
    /// bought is a smaller harm than a shop that will not open.
    public func getOrders(for owner: UserID?) -> Orders {
        guard
            let key = Self.filename(for: owner),
            let data = try? Data(contentsOf: url(for: key)),
            let dtos = try? JSONDecoder().decode([OrderDTO].self, from: data)
        else {
            return Orders()
        }
        return Orders(dtos.compactMap { $0.toDomain() })
    }

    public func setOrders(_ orders: Orders, for owner: UserID?) async {
        guard let key = Self.filename(for: owner) else { return }
        let dtos = orders.all.map(OrderDTO.init(from:))
        let directory = self.directory
        let url = url(for: key)

        await Task.detached(priority: .utility) {
            Self.write(dtos, to: url, in: directory)
        }.value
    }

    private static func write(_ dtos: [OrderDTO], to url: URL, in directory: URL) {
        guard let data = try? JSONEncoder().encode(dtos) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func url(for key: String) -> URL {
        directory.appending(path: "\(key).json", directoryHint: .notDirectory)
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: what something is filed
    /// under is the storage layer's business. Nothing at all for a guest — an order belongs to
    /// somebody, and a guest is nobody to file one under.
    private static func filename(for owner: UserID?) -> String? {
        owner.map { String($0.rawValue) }
    }
}
