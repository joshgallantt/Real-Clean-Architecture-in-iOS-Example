public protocol ProductRepository: Sendable {
    func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError>
    func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError>
    func getProduct(id: ProductID) async -> Result<Product, ProductError>
    func getCategories() async -> Result<[ProductCategory], ProductError>
}
