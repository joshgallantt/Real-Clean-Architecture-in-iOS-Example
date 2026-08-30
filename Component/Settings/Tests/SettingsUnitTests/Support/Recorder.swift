import Combine
import Foundation
@testable import Settings

/// Every value a publisher put out, in order, so a test can say what changed as well as what is
/// there now.
@MainActor
final class Recorder {
    private(set) var published: [[Setting]] = []
    private var cancellable: AnyCancellable?

    init(_ publisher: AnyPublisher<[Setting], Never>) {
        cancellable = publisher.sink { [weak self] in self?.published.append($0) }
    }

    var latest: [Setting] { published.last ?? [] }
}
