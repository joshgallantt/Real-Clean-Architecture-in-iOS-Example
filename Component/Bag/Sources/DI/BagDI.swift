import Combine
import Foundation
import Bag
import BagData
import Session

/// Martin, *Clean Architecture* (2017), Ch. 26 — The Main Component: wiring, and nothing else. It
/// is the only thing that knows the concrete types, so it is the only thing that has to change when
/// one is swapped. Not unit tested — there is no behaviour here to test.
///
/// Fowler, *Inversion of Control Containers and the Dependency Injection Pattern* (2004) —
/// Dependency Injection.
public struct BagDI {
    private let repository: BagRepository

    public let observeBagUseCase: ObserveBagUseCase
    public let observeBagChangesUseCase: ObserveBagChangesUseCase
    public let observeBagItemQuantityUseCase: ObserveBagItemQuantityUseCase
    public let addItemToBagUseCase: AddItemToBagUseCase
    public let setBagItemQuantityUseCase: SetBagItemQuantityUseCase
    public let bringBagUpToDateUseCase: BringBagUpToDateUseCase
    public let acknowledgeBagChangeUseCase: AcknowledgeBagChangeUseCase

    @MainActor
    public init(
        getSession: GetSessionUseCase,
        observeSession: ObserveSessionUseCase,
        store: BagStore = FileBagStore()
    ) {
        /// Evans, *Domain-Driven Design* (2003) — Bounded Context: turning a session into an owner
        /// happens here, once, at the wiring boundary. What the repository receives is who the bag
        /// belongs to.
        let repository = DefaultBagRepository(
            store: store,
            owner: BagOwner(getSession()),
            ownerPublisher: observeSession()
                .map(BagOwner.init)
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
        self.repository = repository

        self.observeBagUseCase = DefaultObserveBagUseCase(repository: repository)
        self.observeBagChangesUseCase = DefaultObserveBagChangesUseCase(repository: repository)
        self.observeBagItemQuantityUseCase = DefaultObserveBagItemQuantityUseCase(repository: repository)
        self.addItemToBagUseCase = DefaultAddItemToBagUseCase(repository: repository)
        self.setBagItemQuantityUseCase = DefaultSetBagItemQuantityUseCase(repository: repository)
        self.bringBagUpToDateUseCase = DefaultBringBagUpToDateUseCase(repository: repository)
        self.acknowledgeBagChangeUseCase = DefaultAcknowledgeBagChangeUseCase(repository: repository)
    }
}
