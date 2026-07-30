import Networking
import Product

public struct DefaultProductRepository: ProductRepository {
    private let client: ProductClient

    public init(client: ProductClient) {
        self.client = client
    }

    public func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        do {
            let dtos = try await client.fetchProducts(query: query)
            return .success(dtos.map { $0.toDomain() })
        } catch {
            return .failure(Self.productError(from: error))
        }
    }

    // The catalog has no endpoint for a set of ids, so each one is fetched on its own.
    // A product that 404s has been delisted since its id was stored and is simply gone;
    // any other failure means the set could not be assembled, and a short list would be
    // indistinguishable from the shopper having chosen fewer things.
    public func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError> {
        guard !ids.isEmpty else { return .success([]) }

        let client = self.client
        let fetched = await withTaskGroup(of: (ProductID, Result<Product, ProductError>).self) { group in
            for id in ids {
                group.addTask {
                    do {
                        return (id, .success(try await client.fetchProduct(id: id).toDomain()))
                    } catch {
                        return (id, .failure(Self.productError(from: error)))
                    }
                }
            }

            var results: [ProductID: Result<Product, ProductError>] = [:]
            for await (id, result) in group {
                results[id] = result
            }
            return results
        }

        for id in ids {
            guard case .failure(let error) = fetched[id], error != .notFound else { continue }
            return .failure(error)
        }

        return .success(ids.compactMap { id in
            guard case .success(let product) = fetched[id] else { return nil }
            return product
        })
    }

    public func getProduct(id: ProductID) async -> Result<Product, ProductError> {
        do {
            let dto = try await client.fetchProduct(id: id)
            return .success(dto.toDomain())
        } catch {
            return .failure(Self.productError(from: error))
        }
    }

    public func getCategories() async -> Result<[ProductCategory], ProductError> {
        do {
            let dtos = try await client.fetchCategories()
            return .success(dtos.map { $0.toDomain() })
        } catch {
            return .failure(Self.productError(from: error))
        }
    }

    // The one place the transport's vocabulary becomes the domain's. Only a 404 tells
    // us a product is genuinely gone; a timeout, a 500 and an unreadable payload are
    // all the same thing to a shopper — the app could not get what it asked for.
    private static func productError(from error: Error) -> ProductError {
        guard case .server(404) = error as? HTTPClientError else { return .unavailable }
        return .notFound
    }
}
