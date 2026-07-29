import Combine

/// Access to the shopper's bag and to what they still need to be told about it.
///
/// Two aggregates, one repository, because they have to be kept together: a crash
/// between two writes could leave a warning about a line that is still in the bag, or a
/// bag missing a line with nothing to say why. Saving them in one go is the only way
/// that cannot happen.
public protocol BagRepository: Sendable {
    @MainActor
    var bag: Bag { get }

    @MainActor
    var bagPublisher: AnyPublisher<Bag, Never> { get }

    @MainActor
    var changes: BagChanges { get }

    @MainActor
    var changesPublisher: AnyPublisher<BagChanges, Never> { get }

    @MainActor
    func save(bag: Bag, changes: BagChanges)
}
