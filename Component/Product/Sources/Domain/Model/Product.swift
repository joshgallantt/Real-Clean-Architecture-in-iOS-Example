import Foundation

public struct Product: Equatable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let description: String
    public let category: CategoryID
    public let price: Double
    public let discountPercentage: Double
    public let rating: Double
    public let stock: Int

    /// Whether the shop expects to have this again. Only meaningful when `stock` is
    /// none — a shopper looking at something in stock has no use for it.
    public let willRestock: Bool
    public let brand: String
    public let thumbnail: String
    public let images: [String]

    public var isInStock: Bool { stock > 0 }

    public init(
        id: Int,
        title: String,
        description: String,
        category: CategoryID,
        price: Double,
        discountPercentage: Double,
        rating: Double,
        stock: Int,
        willRestock: Bool,
        brand: String,
        thumbnail: String,
        images: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.willRestock = willRestock
        self.brand = brand
        self.thumbnail = thumbnail
        self.images = images
    }
}
