import Foundation
import Money
import Product

enum DemoCatalogMischief {
    nonisolated static func meddle(with product: Product) -> Product {
        let price = switch product.id.rawValue % 3 {
        case 0: product.price.scaled(by: 1.2)
        case 1: product.price.scaled(by: 0.8)
        default: product.price
        }

        let availability: Availability = if product.id.rawValue % 10 == 0 {
            .discontinued
        } else if product.id.rawValue % 5 == 0 {
            .outOfStock
        } else {
            product.availability
        }

        return Product(
            id: product.id,
            title: product.title,
            description: product.description,
            category: product.category,
            price: price,
            rating: product.rating,
            availability: availability,
            brand: product.brand,
            thumbnail: product.thumbnail,
            images: product.images
        )
    }
}

// MARK: - Decorators

struct DemoBrowseCatalogUseCase: BrowseCatalogUseCase {
    let wrapped: BrowseCatalogUseCase

    func callAsFunction(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        await wrapped(matching: query).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

struct DemoLookUpProductsUseCase: LookUpProductsUseCase {
    let wrapped: LookUpProductsUseCase

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped(ids: ids).map { $0.map(DemoCatalogMischief.meddle) }
    }
}

struct DemoViewProductUseCase: ViewProductUseCase {
    let wrapped: ViewProductUseCase

    func callAsFunction(id: ProductID) async -> Result<Product, ProductError> {
        await wrapped(id: id).map(DemoCatalogMischief.meddle)
    }
}

private extension Money {
    nonisolated func scaled(by factor: Double) -> Money {
        Money(minorUnits: Int((Double(minorUnits) * factor).rounded()), currency: currency)
    }
}
