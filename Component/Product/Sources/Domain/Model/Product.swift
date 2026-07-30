import Money

/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: an entity, immutable and
/// framework-free.
///
/// Evans, *Domain-Driven Design* (2003) — Entities.
public struct Product: Equatable, Hashable, Sendable, Identifiable {
    public let id: ProductID
    public let title: String
    public let description: String
    public let category: CategoryID
    public let price: Money
    public let rating: Double
    public let availability: Availability
    public let brand: String
    public let thumbnail: String
    public let images: [String]

    public init(
        id: ProductID,
        title: String,
        description: String,
        category: CategoryID,
        price: Money,
        rating: Double,
        availability: Availability,
        brand: String,
        thumbnail: String,
        images: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.price = price
        self.rating = rating
        self.availability = availability
        self.brand = brand
        self.thumbnail = thumbnail
        self.images = images
    }
}
