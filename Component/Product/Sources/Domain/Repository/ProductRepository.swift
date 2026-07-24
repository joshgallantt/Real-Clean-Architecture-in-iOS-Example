public protocol ProductRepository: Sendable {
    func getProducts(matching query: ProductQuery) async -> Result<[Product], ProductError>
    func getProduct(id: Int) async -> Result<Product, ProductError>
    func getCategories() async -> Result<[ProductCategory], ProductError>
}
