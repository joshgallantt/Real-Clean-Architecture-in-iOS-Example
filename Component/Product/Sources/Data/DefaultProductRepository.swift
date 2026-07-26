import Product

public struct DefaultProductRepository: ProductRepository {
    private static let maxConcurrentFetches = 6

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

    // Fans out over a bounded window rather than awaiting each id in turn, so a
    // page of ids costs a few round trips instead of one per item. Ids that 404
    // are dropped; only a wholly failed batch surfaces as an error.
    public func getProducts(ids: [Int]) async -> Result<[Product], ProductError> {
        guard !ids.isEmpty else { return .success([]) }

        let client = self.client
        let fetched = await withTaskGroup(of: (Int, Product?).self) { group in
            var iterator = ids.makeIterator()
            var results: [Int: Product] = [:]

            for _ in 0..<Self.maxConcurrentFetches {
                guard let id = iterator.next() else { break }
                group.addTask { (id, try? await client.fetchProduct(id: id).toDomain()) }
            }

            while let (id, product) = await group.next() {
                if let product {
                    results[id] = product
                }
                if let next = iterator.next() {
                    group.addTask { (next, try? await client.fetchProduct(id: next).toDomain()) }
                }
            }

            return results
        }

        guard !fetched.isEmpty else { return .failure(.networkFailure) }
        return .success(ids.compactMap { fetched[$0] })
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
