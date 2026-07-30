import Product
import ProductData
import ProductDI

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: the feature wired exactly as
/// the composition root wires it. Nothing here reaches past a use case into a repository, a client
/// or a DTO.
struct Shop {
    let catalog: FakeCatalog
    private let di: ProductDI

    init(catalog: FakeCatalog = FakeCatalog()) {
        self.catalog = catalog
        self.di = ProductDI(client: DummyJSONProductClient(httpClient: catalog))
    }

    func browse(page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        await di.browseCatalogUseCase(matching: .all(page: page, pageSize: pageSize))
    }

    func search(_ text: String, page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        guard let term = SearchTerm(text) else { return .success([]) }
        return await di.browseCatalogUseCase(matching: .search(term, page: page, pageSize: pageSize))
    }

    func browse(_ category: ProductCategory, page: Int = 0, pageSize: Int = 30) async -> Result<[Product], ProductError> {
        await di.browseCatalogUseCase(matching: .category(category, page: page, pageSize: pageSize))
    }

    func categories() async -> Result<[ProductCategory], ProductError> {
        await di.browseCategoriesUseCase()
    }

    func open(productId: Int) async -> Result<Product, ProductError> {
        await di.viewProductUseCase(id: ProductID(rawValue: productId))
    }

    func products(withIds ids: [Int]) async -> Result<[Product], ProductError> {
        await di.lookUpProductsUseCase(ids: ids.map { ProductID(rawValue: $0) })
    }
}

extension Result {
    var success: Success? { try? get() }
}
