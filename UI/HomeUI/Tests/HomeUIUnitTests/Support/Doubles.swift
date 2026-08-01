import Foundation
import Money
import Product
import SnackbarUI
@testable import HomeUI

@MainActor
final class StubBrowseCatalog: BrowseCatalogUseCase, @unchecked Sendable {
    var result: Result<[Product], ProductError> = .success([])
    private(set) var queries: [CatalogQuery] = []

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        queries.append(query)
        return result
    }
}

@MainActor
final class SpySnackbarPresenter: SnackbarPresenting {
    private(set) var shown: [Snackbar] = []

    func show(_ snackbar: Snackbar) {
        shown.append(snackbar)
    }
}

@MainActor
func yieldUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<1_000 where !isSatisfied() { await Task.yield() }
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
