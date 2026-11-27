import Bag

/// Answers with what a test says the shop said, and counts how often it was asked.
@MainActor
public final class SpyCheckBagUseCase: CheckBagUseCase {
    public var answer: CheckedBag
    public private(set) var callCount = 0

    public init(answer: CheckedBag) {
        self.answer = answer
    }

    public func callAsFunction() async -> CheckedBag {
        callCount += 1
        return answer
    }
}
