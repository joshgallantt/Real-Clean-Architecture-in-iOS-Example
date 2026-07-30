import Foundation

/// What the shop's backend puts on the wire. Deliberately not a domain type — these
/// tests seed a backend, they do not construct domain models.
struct CatalogItem: Encodable {
    var id: Int
    var title: String
    var description: String = "A description."
    var category: String
    var price: Double = 9.99
    var discountPercentage: Double = 0
    var rating: Double = 4.5
    var stock: Int = 10
    var willRestock: Bool? = nil
    var brand: String? = "Acme"
    var thumbnail: String = "https://cdn.example.com/thumb.png"
    var images: [String] = ["https://cdn.example.com/1.png"]
}

extension CatalogItem {
    static let sampleCatalog: [CatalogItem] = [
        CatalogItem(id: 1, title: "Mascara Lash Princess", category: "beauty", price: 9.99, brand: "Essence"),
        CatalogItem(id: 2, title: "Eyeshadow Palette", category: "beauty", price: 19.99, brand: "Glamour"),
        CatalogItem(id: 3, title: "Powder Canister", category: "beauty", price: 14.99, brand: "Velvet Touch"),
        CatalogItem(id: 4, title: "Red Lipstick", category: "beauty", price: 12.99, brand: "Chic Cosmetics"),
        CatalogItem(id: 5, title: "Calvin Klein CK One", category: "fragrances", price: 49.99, brand: "Calvin Klein"),
        CatalogItem(id: 6, title: "Dolce Shine Eau de", category: "fragrances", price: 69.99, brand: "Dolce & Gabbana"),
        CatalogItem(id: 7, title: "Annibale Colombo Bed", category: "furniture", price: 1899.99, brand: nil),
        CatalogItem(id: 8, title: "Annibale Colombo Sofa", category: "furniture", price: 2499.99, brand: "Annibale Colombo")
    ]
}
