import Networking
import Product

/// Evans, *Domain-Driven Design* (2003), Ch. 6 — Repositories. Fowler, *PoEAA* (2002), Ch. 13 —
/// Repository: it keeps and hands back aggregates and decides nothing about what they mean.
///
/// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the one exception is what
/// counts as a product at all. A payload the shop has stopped selling is dropped here rather than
/// carried inward as a state to be checked for, so "gone" reaches the domain the same way whether
/// the shop said so or simply stopped answering: nothing comes back.
public struct DefaultProductRepository: ProductRepository {
    private let client: ProductClient

    public init(client: ProductClient) {
        self.client = client
    }

    public func getProducts(matching query: CatalogQuery) async -> Result<[Product], ProductError> {
        do {
            let dtos = try await client.fetchProducts(query: query)
            return .success(dtos.filter(\.isStillSold).map { $0.toDomain() })
        } catch {
            return .failure(Self.productError(from: error))
        }
    }

    public func getProducts(ids: [ProductID]) async -> Result<[Product], ProductError> {
        guard !ids.isEmpty else { return .success([]) }

        let client = self.client
        let fetched = await withTaskGroup(of: (ProductID, Result<Product, ProductError>).self) { group in
            var results: [ProductID: Result<Product, ProductError>] = [:]
            var next = 0

            while next < ids.count, next < Self.atMostAtOnce {
                let id = ids[next]
                group.addTask { await Self.fetch(id, from: client) }
                next += 1
            }

            while let (id, result) = await group.next() {
                results[id] = result

                if next < ids.count {
                    let id = ids[next]
                    group.addTask { await Self.fetch(id, from: client) }
                    next += 1
                }
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
            guard dto.isStillSold else { return .failure(.notFound) }
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

    /// How many of a list to ask for at once. A bag or a wishlist can hold a hundred things and
    /// this catalog answers one id per request, so asking for all of them at once would open a
    /// hundred connections.
    ///
    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: how a list of ids
    /// becomes requests is the outermost ring's business. A caller asks for the products it holds
    /// ids for and is answered; it does not ration the question to protect a transport it is not
    /// supposed to know about. The day this backend grows an endpoint taking many ids, that is a
    /// change to this file and nothing else.
    private static let atMostAtOnce = 10

    private static func fetch(
        _ id: ProductID,
        from client: ProductClient
    ) async -> (ProductID, Result<Product, ProductError>) {
        do {
            let dto = try await client.fetchProduct(id: id)
            guard dto.isStillSold else { return (id, .failure(.notFound)) }
            return (id, .success(dto.toDomain()))
        } catch {
            return (id, .failure(productError(from: error)))
        }
    }

    /// Martin, *Clean Architecture* (2017), Ch. 22 — The Clean Architecture: the one place the
    /// transport's vocabulary becomes the domain's.
    private static func productError(from error: Error) -> ProductError {
        guard case .server(404) = error as? HTTPClientError else { return .unavailable }
        return .notFound
    }
}
