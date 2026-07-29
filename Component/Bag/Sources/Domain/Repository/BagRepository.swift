import Combine

/// Access to the shopper's bag and to what they still need to be told about it.
///
/// Two aggregates, one repository. Not because they must be written atomically — if that
/// were required they would be one aggregate — but because there is one reason for this
/// to change: they share a file, a user key, and a sign-in. Whether a notice still makes
/// sense against a given bag is decided when they are read, by
/// `BagReconciliation.applicable(_:to:)`, so a write that tears corrects itself.
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
