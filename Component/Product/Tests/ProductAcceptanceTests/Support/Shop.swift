import Product
import ProductData
import ProductDI

/// The app's product feature, wired exactly as the composition root wires it, over a
/// fake backend. Tests drive it only through the use cases the UI is given — nothing
/// reaches past this into a repository, a client or a DTO.
struct Shop {
    let catalog: FakeCatalog
    private let di: ProductDI

    init(catalog: FakeCatalog = FakeCatalog()) {
        self.catalog = catalog
        self.di = ProductDI(client: DummyJSONProductClient(httpClient: catalog))
    }

    func browse(page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        await di.getProductsUseCase(matching: .all(page: page, pageSize: pageSize))
    }

    func search(_ text: String, page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        await di.getProductsUseCase(matching: .search(text, page: page, pageSize: pageSize))
    }

    func browse(_ category: ProductCategory, page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        await di.getProductsUseCase(matching: .category(category, page: page, pageSize: pageSize))
    }

    func categories() async -> Result<[ProductCategory], ProductError> {
        await di.getCategoriesUseCase()
    }

    func open(productId: Int) async -> Result<Product, ProductError> {
        await di.getProductUseCase(id: productId)
    }

    func products(withIds ids: [Int]) async -> Result<[Product], ProductError> {
        await di.getProductsByIdsUseCase(ids: ids)
    }
}

extension Result {
    var success: Success? { try? get() }
}
