import Product

public struct DefaultProductRepository: ProductRepository {
    private let client: ProductClient

    public init(client: ProductClient) {
        self.client = client
    }

    public func getProducts(matching query: ProductQuery) async -> Result<[Product], ProductError> {
        do {
            let dtos = try await client.fetchProducts(query: query)
            return .success(dtos.map { $0.toDomain() })
        } catch {
            return .failure(.networkFailure)
        }
    }

    public func getProduct(id: Int) async -> Result<Product, ProductError> {
        do {
            let dto = try await client.fetchProduct(id: id)
            return .success(dto.toDomain())
        } catch {
            return .failure(.networkFailure)
        }
    }

    public func getCategories() async -> Result<[ProductCategory], ProductError> {
        do {
            let dtos = try await client.fetchCategories()
            return .success(dtos.map { $0.toDomain() })
        } catch {
            return .failure(.networkFailure)
        }
    }
}
