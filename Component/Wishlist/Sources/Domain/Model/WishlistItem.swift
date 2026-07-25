import Foundation

public struct WishlistItem: Equatable, Sendable, Identifiable {
    public let id: Int
    public let dateAdded: Date

    public init(id: Int, dateAdded: Date = Date()) {
        self.id = id
        self.dateAdded = dateAdded
    }
}
