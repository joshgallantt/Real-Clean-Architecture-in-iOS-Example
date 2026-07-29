import Combine
import Foundation
import Bag

/// A working bag repository, not a stub with canned answers: it keeps what it is given
/// and hands it back. The use cases under test genuinely read, apply and save.
@MainActor
final class InMemoryBagRepository: BagRepository {
    private let subject: CurrentValueSubject<Bag, Never>

    /// Every bag handed over, in order, so a test can see what a use case decided to
    /// save rather than only where things ended up.
    private(set) var saved: [Bag] = []

    init(_ bag: Bag = Bag()) {
        self.subject = CurrentValueSubject(bag)
    }

    var bag: Bag { subject.value }

    var bagPublisher: AnyPublisher<Bag, Never> { subject.eraseToAnyPublisher() }

    func save(_ bag: Bag) {
        saved.append(bag)
        subject.value = bag
    }
}
