import Combine
import Foundation
import Testing
import Bag

/// What each use case is for: naming one thing a shopper does, and sequencing it —
/// read the bag, ask the bag to apply the change, keep the result. The rules about what
/// the change means belong to `Bag` and are asserted in `BagChangeTests`; these assert
/// that the right change is asked for and that the result is kept.
@MainActor
@Suite("Doing something to the bag")
struct BagUseCaseTests {

    @Test("Choosing something saves a bag with it in")
    func addingSaves() {
        let repository = InMemoryBagRepository()
        let add = DefaultAddItemToBagUseCase(repository: repository)

        add(BagItem(id: 1, lastKnownPrice: 9.99))

        #expect(repository.saved.count == 1)
        #expect(repository.bag.items.map(\.id) == [1])
    }

    @Test("Choosing builds on the bag the shopper already has, rather than replacing it")
    func addingReadsBeforeItWrites() {
        let repository = InMemoryBagRepository(Bag(items: [BagItem(id: 1, lastKnownPrice: 1)]))
        let add = DefaultAddItemToBagUseCase(repository: repository)

        add(BagItem(id: 2, lastKnownPrice: 2))

        #expect(repository.bag.items.map(\.id).sorted() == [1, 2])
    }

    @Test("Putting something back is asking for none of it, and saves a bag without it")
    func askingForNoneRemoves() {
        let repository = InMemoryBagRepository(Bag(items: [
            BagItem(id: 1, lastKnownPrice: 1),
            BagItem(id: 2, lastKnownPrice: 2)
        ]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(itemId: 1, to: 0)

        #expect(repository.bag.items.map(\.id) == [2])
    }

    @Test("Changing how many saves a bag with the new count")
    func changingQuantitySaves() {
        let repository = InMemoryBagRepository(Bag(items: [BagItem(id: 1, lastKnownPrice: 4.99)]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(itemId: 1, to: 3)

        #expect(repository.bag.total.cents == 1497)
    }

    @Test("Asking about something that isn't in the bag saves nothing at all")
    func settingQuantityOfAbsentItem() {
        let repository = InMemoryBagRepository(Bag(items: [BagItem(id: 1, lastKnownPrice: 1)]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(itemId: 99, to: 5)

        #expect(repository.bag.items.map(\.id) == [1])
    }

    @Test("Watching the bag reports it as it is now, and again on every change")
    func observing() {
        let repository = InMemoryBagRepository()
        let observe = DefaultObserveBagUseCase(repository: repository)
        let add = DefaultAddItemToBagUseCase(repository: repository)
        var seen: [Int] = []
        let cancellable = observe().sink { seen.append($0.itemCount) }

        add(BagItem(id: 1, lastKnownPrice: 1))
        add(BagItem(id: 1, lastKnownPrice: 1))

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("Watching one line's count ignores the rest of the bag moving around it")
    func watchingOneQuantity() {
        let repository = InMemoryBagRepository()
        let quantity = DefaultBagItemQuantityUseCase(repository: repository)
        let add = DefaultAddItemToBagUseCase(repository: repository)
        var seen: [Int] = []
        let cancellable = quantity(itemId: 7).sink { seen.append($0) }

        add(BagItem(id: 7, lastKnownPrice: 1))
        add(BagItem(id: 99, lastKnownPrice: 1))
        add(BagItem(id: 7, lastKnownPrice: 1))

        // Adding something else changed the bag but not this line's count, so a product
        // tile showing a badge for item 7 is not redrawn for it.
        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }
}
