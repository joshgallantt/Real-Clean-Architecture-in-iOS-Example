import Bag
import Product
import ProductTestSupport

@MainActor
public final class SpyAddItemToBagUseCase: AddItemToBagUseCase {
    public private(set) var added: [BagItem] = []

    public init() {}

    public func callAsFunction(_ item: BagItem) {
        added.append(item)
    }
}
