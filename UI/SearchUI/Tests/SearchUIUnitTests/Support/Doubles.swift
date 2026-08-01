import Foundation
import Money
import Product
import SearchHistory
import SnackbarUI
@testable import SearchUI

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
final class StubBrowseCategories: BrowseCategoriesUseCase, @unchecked Sendable {
    var result: Result<[ProductCategory], ProductError> = .success([])
    private(set) var callCount = 0

    func callAsFunction() async -> Result<[ProductCategory], ProductError> {
        callCount += 1
        return result
    }
}

@MainActor
final class StubGetSearchHistory: GetSearchHistoryUseCase, @unchecked Sendable {
    var history = SearchHistory()

    func callAsFunction() -> SearchHistory { history }
}

@MainActor
final class SpyClearSearchHistory: ClearSearchHistoryUseCase, @unchecked Sendable {
    private(set) var callCount = 0

    func callAsFunction() {
        callCount += 1
    }
}

@MainActor
final class SpyRecordSearch: RecordSearchUseCase, @unchecked Sendable {
    private(set) var recorded: [SearchTerm] = []

    func callAsFunction(_ term: SearchTerm) {
        recorded.append(term)
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
func waitUntil(_ isSatisfied: () -> Bool) async {
    for _ in 0..<200 where !isSatisfied() {
        try? await Task.sleep(for: .milliseconds(10))
    }
}

@MainActor
func settle() async {
    for _ in 0..<200 { await Task.yield() }
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
