import Combine
import Foundation
import Bag
import BagData
import Session

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
        // Turning a session into an owner is `BagOwner`'s job, and happens here once. What
        // the repository is handed is who the bag belongs to, never a session.
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
