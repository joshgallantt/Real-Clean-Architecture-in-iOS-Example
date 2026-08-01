import Foundation
import Money
import Product
@testable import ProductUI

@MainActor
final class StubViewProduct: ViewProductUseCase, @unchecked Sendable {
    var result: Result<Product, ProductError> = .success(.fixture(id: 1))
    private(set) var calls: [ProductID] = []

    func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        calls.append(id)
        return result
    }
}

// MARK: - Fixtures

func pid(_ value: Int) -> ProductID {
    ProductID(rawValue: value)
}

extension Product {
    static func fixture(id: Int) -> Product {
        Product(
            id: pid(id),
            title: "Product \(id)",
            description: "",
            category: CategoryID(rawValue: "beauty"),
            price: Money(amount: 9.99, currency: .usd),
            rating: 4.5,
            availability: .inStock(remaining: 10),
            brand: "Acme",
            thumbnail: "https://cdn.example.com/\(id).png",
            images: []
        )
    }
}
