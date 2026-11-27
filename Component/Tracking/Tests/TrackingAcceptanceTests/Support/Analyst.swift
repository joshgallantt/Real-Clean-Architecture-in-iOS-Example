import Foundation
import Tracking
import TrackingData
import TrackingDI
import TrackingTestSupport

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A screen says
/// what a shopper saw and did; the analyst reads what reached GA4, as a person watching Console
/// would see it.
///
/// Martin, Ch. 26 — The Main Component: the component wired as the composition root wires it — its
/// use cases in front of the GA4 destination — with the two edges it cannot own here, the unified
/// log and the system's consent prompt, swapped for ones a test can read and answer.
final class Analyst {
    private let log = SpyTrackingLog()
    private let di: TrackingDI

    init(shopperHasSaid status: TrackingConsentStatus, andWillSay answer: TrackingConsentStatus) {
        di = TrackingDI(
            destinations: [GA4Destination(log: log, batchWindow: .seconds(60))],
            consent: StubTrackingConsentSource(status: status, answer: answer)
        )
    }

    func screenIsViewed(_ screen: String) {
        di.trackScreenViewUseCase(screen)
    }

    func cardIsSeen(_ id: Int, at index: Int, in list: TrackingContext.List, on screen: String) {
        di.trackElementViewUseCase("product", about: anItem(id, price: 9.99, quantity: 1), in: .list(screen, list, index: index))
    }

    func cardIsTapped(_ id: Int, at index: Int, in list: TrackingContext.List, on screen: String) {
        di.trackElementInteractionUseCase("product", about: anItem(id, price: 9.99, quantity: 1), in: .list(screen, list, index: index))
    }

    func buttonIsTapped(_ name: String, on screen: String) {
        di.trackElementInteractionUseCase(name, in: .screen(screen))
    }

    func shopperIsAskedAboutTracking() async {
        await di.requestTrackingConsentUseCase()
    }

    func appGoesToTheBackground() {
        di.sendHeldTrackingUseCase()
    }

    /// Each line read back as GA4 reads it: an event name and its parameters.
    var events: [Event] {
        log.entries.compactMap { line in
            guard
                let object = (try? JSONSerialization.jsonObject(with: Data(line.utf8))) as? [String: Any],
                let name = object["name"] as? String,
                let params = object["params"] as? [String: Any]
            else {
                return nil
            }
            return Event(name: name, params: params)
        }
    }

    struct Event {
        let name: String
        let params: [String: Any]

        func text(_ key: String) -> String? { params[key] as? String }
        var items: [[String: Any]] { params["items"] as? [[String: Any]] ?? [] }
    }
}
