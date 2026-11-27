import Bag

@MainActor
public final class SpySetBagItemUseCase: SetBagItemUseCase {
    public private(set) var calls: [BagItem] = []

    public init() {}

    public func callAsFunction(_ item: BagItem) {
        calls.append(item)
    }
}
