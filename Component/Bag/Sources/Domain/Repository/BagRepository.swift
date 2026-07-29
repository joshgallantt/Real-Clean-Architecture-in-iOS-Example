import Combine

/// Access to the shopper's bag, and nothing else. What a change to the bag *means* is
/// the bag's own business, and deciding which change to make is the use case's — so
/// this offers no menu of mutations, only the aggregate and a way to keep it.
public protocol BagRepository: Sendable {
    @MainActor
    var bag: Bag { get }

    @MainActor
    var bagPublisher: AnyPublisher<Bag, Never> { get }

    @MainActor
    func save(_ bag: Bag)
}
