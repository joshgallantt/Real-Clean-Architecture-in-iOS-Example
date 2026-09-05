import Product
import SearchHistory

@MainActor
public final class SpyRecordSearchUseCase: RecordSearchUseCase {
    public init() {}

    public private(set) var recorded: [SearchTerm] = []

    public func callAsFunction(_ term: SearchTerm) {
        recorded.append(term)
    }
}
