import Foundation
import Networking

struct PagePayload: Encodable {
    let products: [CatalogItem]
    let total: Int
    let skip: Int
    let limit: Int
}
