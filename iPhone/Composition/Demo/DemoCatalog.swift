import Foundation
import Money
import Product

/// Martin, *Clean Architecture* (2017), Ch. 9 — Liskov Substitution Principle: decorators standing
/// in for the real use cases. Nothing below the app layer knows a demo is possible — `Component/Bag`
/// sees ordinary catalog answers and reacts exactly as it would in production.
///
/// Deterministic, so a demo can be repeated and a screenshot reproduced: every third product costs
/// more, every third costs less, every fifth has sold out and every tenth is gone for good — enough
/// overlap that some lines report two changes at once.
enum DemoCatalogMischief {
    nonisolated static func meddle(with product: Product) -> Product {
        let price = switch product.id.rawValue % 3 {
        case 0: scaled(product.price, by: 1.2)
        case 1: scaled(product.price, by: 0.8)
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

// MARK: - Decorator


struct DemoLookUpProductsUseCase: LookUpProductsUseCase {
    let wrapped: LookUpProductsUseCase

    func callAsFunction(ids: [ProductID]) async -> Result<[Product], ProductError> {
        await wrapped(ids: ids).map { $0.map(DemoCatalogMischief.meddle) }
    }
}


private nonisolated func scaled(_ amount: Money, by factor: Double) -> Money {
    Money(minorUnits: Int((Double(amount.minorUnits) * factor).rounded()), currency: amount.currency)
}
