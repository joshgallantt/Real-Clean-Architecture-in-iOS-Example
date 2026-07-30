import Combine
import Foundation
import Testing
import Bag
import Money
import Product

@MainActor
@Suite("Doing something to the bag")
/// Martin, *Clean Architecture* (2017), Ch. 20 — Business Rules: what the use case sequences, and
/// what it keeps.
struct BagUseCaseTests {
    @Test("Choosing something saves a bag with it in")
    func addingSaves() {
        let repository = InMemoryBagRepository()
        let add = DefaultAddItemToBagUseCase(repository: repository)

        add(item(1, price: 9.99))

        #expect(repository.saved.count == 1)
        #expect(repository.bag.items.map(\.id) == [pid(1)])
    }

    @Test("Choosing builds on the bag the shopper already has, rather than replacing it")
    func addingReadsBeforeItWrites() {
        let repository = InMemoryBagRepository(Bag(items: [item(1, price: 1)]))
        let add = DefaultAddItemToBagUseCase(repository: repository)

        add(item(2, price: 2))

        #expect(repository.bag.items.map(\.id) == [pid(2), pid(1)])
    }

    @Test("Putting something back is asking for none of it, and saves a bag without it")
    func askingForNoneRemoves() {
        let repository = InMemoryBagRepository(Bag(items: [
            item(1, price: 1),
            item(2, price: 2)
        ]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(productId: pid(1), to: 0)

        #expect(repository.bag.items.map(\.id) == [pid(2)])
    }

    @Test("Changing how many saves a bag with the new count")
    func changingQuantitySaves() {
        let repository = InMemoryBagRepository(Bag(items: [item(1, price: 4.99)]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(productId: pid(1), to: 3)

        #expect(repository.bag.total == usd(14.97))
    }

    @Test("Asking about something that isn't in the bag saves nothing at all")
    func settingQuantityOfAbsentItem() {
        let repository = InMemoryBagRepository(Bag(items: [item(1, price: 1)]))
        let setQuantity = DefaultSetBagItemQuantityUseCase(repository: repository)

        setQuantity(productId: pid(99), to: 5)

        #expect(repository.bag.items.map(\.id) == [pid(1)])
    }

    @Test("Watching the bag reports it as it is now, and again on every change")
    func observing() {
        let repository = InMemoryBagRepository()
        let observe = DefaultObserveBagUseCase(repository: repository)
        let add = DefaultAddItemToBagUseCase(repository: repository)
        var seen: [Int] = []
        let cancellable = observe().sink { seen.append($0.itemCount) }

        add(item(1, price: 1))
        add(item(1, price: 1))

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }

    @Test("Watching one line's count ignores the rest of the bag moving around it")
    func watchingOneQuantity() {
        let repository = InMemoryBagRepository()
        let quantity = DefaultObserveBagItemQuantityUseCase(repository: repository)
        let add = DefaultAddItemToBagUseCase(repository: repository)
        var seen: [Int] = []
        let cancellable = quantity(productId: pid(7)).sink { seen.append($0) }

        add(item(7, price: 1))
        add(item(99, price: 1))
        add(item(7, price: 1))

        #expect(seen == [0, 1, 2])
        cancellable.cancel()
    }
}
