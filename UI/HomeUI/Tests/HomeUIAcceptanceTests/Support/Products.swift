import Product
import ProductTestSupport
@testable import HomeUITestSupport

func products(
    _ ids: ClosedRange<Int>,
    category: String,
    availability: Availability = .inStock(remaining: 10)
) -> [Product] {
    ids.map { Product.fixture(id: $0, category: category, availability: availability) }
}
