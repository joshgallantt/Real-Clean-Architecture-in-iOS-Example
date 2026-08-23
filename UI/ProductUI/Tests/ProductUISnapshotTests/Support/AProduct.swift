import Money
import Product

/// A builder rather than a fixture: each test sets only the field it cares
/// about and inherits the rest, so no test is reading data another test owns.
struct AProduct {
    private var id = 1
    private var title = "Kettle"
    private var brand = "Acme"
    private var price = Money(amount: 24.99, currency: .usd)
    private var availability = Availability.inStock(remaining: 5)

    func named(_ title: String) -> AProduct {
        var copy = self
        copy.title = title
        return copy
    }

    func priced(_ price: Money) -> AProduct {
        var copy = self
        copy.price = price
        return copy
    }

    func soldOut() -> AProduct {
        var copy = self
        copy.availability = .outOfStock
        return copy
    }

    func build() -> Product {
        Product(
            id: ProductID(rawValue: id),
            title: title,
            description: "A kettle that boils water, which is all anybody wants from a kettle.",
            category: CategoryID(rawValue: "home"),
            price: price,
            rating: 4.5,
            availability: availability,
            brand: brand,
            thumbnail: "",
            images: []
        )
    }
}
