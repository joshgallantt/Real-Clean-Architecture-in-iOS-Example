import Foundation

public struct BagItem: Equatable, Sendable, Identifiable {
    public let id: Int
    public let quantity: Int
    public let dateAdded: Date

    public init(id: Int, quantity: Int, dateAdded: Date = Date()) {
        self.id = id
        self.quantity = quantity
        self.dateAdded = dateAdded
    }
}
