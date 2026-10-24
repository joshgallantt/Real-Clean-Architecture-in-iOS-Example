import Foundation
import Networking

struct CategoryPayload: Encodable {
    let slug: String
    let name: String

    static let sampleCategories = [
        CategoryPayload(slug: "beauty", name: "Beauty"),
        CategoryPayload(slug: "fragrances", name: "Fragrances"),
        CategoryPayload(slug: "furniture", name: "Furniture")
    ]
}
