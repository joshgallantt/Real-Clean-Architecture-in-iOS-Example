import Foundation
import Tracking
import TrackingData
import TrackingDI
import TrackingTestSupport

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 28 — The Test Boundary: the testing API. A screen says
/// what a shopper saw and did; the analyst reads what reached Firebase, as a person watching Console
/// would see it.
///
/// Martin, Ch. 26 — The Main Component: the component wired as the composition root wires it — its
/// use cases in front of its clients — with the edges it cannot own here, the vendors, the unified
/// log and the system's consent prompt, swapped for ones a test can read and answer.
final class Analyst {
    private let firebase = SpyFirebaseClient()
    private let di: TrackingDI

    init(shopperHasSaid status: TrackingConsentStatus, andWillSay answer: TrackingConsentStatus) {
        di = TrackingDI(
            firebase: firebase,
            mParticle: SpyMParticleClient(),
            logger: SpyLoggerClient(),
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

    /// What reached Firebase, in the order it was sent.
    var events: [FirebaseEventDTO] { firebase.events }
}
