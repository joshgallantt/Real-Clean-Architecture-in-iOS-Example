import Product

public struct ProductDTO: Decodable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double
    let rating: Double
    let stock: Int
    let willRestock: Bool?
    let brand: String?
    let thumbnail: String
    let images: [String]

    func toDomain() -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            category: CategoryID(rawValue: category),
            price: price,
            discountPercentage: discountPercentage,
            rating: rating,
            stock: stock,
            willRestock: willRestock ?? true,
            brand: brand ?? "",
            thumbnail: thumbnail,
            images: images
        )
    }
}

struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]
    let total: Int
    let skip: Int
    let limit: Int
}
