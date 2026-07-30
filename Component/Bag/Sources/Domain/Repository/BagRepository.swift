import Combine

/// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle; Ch. 7 — Single
/// Responsibility Principle: two aggregates behind one repository, because they have one reason to
/// change — they share a file, an owner and a sign-in, and are always read together. Whether a
/// notice still holds against a given bag is decided on read, so a write that tears corrects
/// itself.
///
/// Evans, *Domain-Driven Design* (2003) — Repositories. Fowler, *PoEAA* (2002) — Repository;
/// Separated Interface.
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
