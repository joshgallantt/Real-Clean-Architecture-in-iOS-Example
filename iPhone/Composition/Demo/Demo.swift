import Foundation
import Networking
import ProductData
import ProductDI

/// Martin, *Clean Architecture* (2017), Ch. 8 — Open/Closed Principle: a demo is added by writing a
/// new `Catalog`, not by editing the app around it. The exemplar stays the thing worth reading, and
/// a demo cannot leak into it.
///
/// Martin, Ch. 26 — The Main Component: which catalog the app runs on is chosen at one line, in the
/// only layer allowed to choose concrete types. Both arrangements compile at all times, so a demo
/// cannot rot and switching one on is never a matter of uncommenting code.
///
/// To run it, set `isOn` to `true` and rebuild.
///
/// The shop decides what it is like when the app starts, and holds to it. Around one product in five
/// has sold out: its card carries a bell instead of a bag button and its page offers Notify Me
/// instead of Add to Bag. Others cost more or less than they did, and one in ten has been dropped
/// altogether — you will not find those, which is the point of them.
///
/// The bag is where a shopper sees it happen, and it needs two visits, because the shop only changes
/// its mind between them. Fill a bag, taking two of at least one thing. Then **quit the app and open
/// it again**: prices have moved both ways, a line is short, and some have gone — out of stock in
/// one section, stopped-selling in another. Tap Okay on one and it stays; tap the remove button on a
/// dearer one and it goes with its notice. Notices a shopper never read are still waiting the launch
/// after that, because they are kept with the bag.
enum Demo {
    static let isOn = true

    /// A shop that changes its mind between visits.
    ///
    /// The meddling sits under the use cases rather than around them, so every question about a
    /// product — a grid, a search, a category, a product's own page, and the lookups the bag and the
    /// wishlist make — is answered by one thing that has already decided. Nothing has to agree with
    /// anything, because there is only one answer.
    static func shopThatChangesItsMind() -> Catalog {
        Catalog(ProductDI(repository: DemoProductRepository(
            wrapped: DefaultProductRepository(
                client: DummyJSONProductClient(httpClient: URLSessionHTTPClient(session: .shared))
            ),
            shop: DemoShop(offset: thisVisit())
        )))
    }

    /// How many times the app has been opened, which is what the shop's rotation runs on.
    ///
    /// It is counted here rather than in `DataAssembler` because nothing but a demo has any use for
    /// it — the exemplar does not gain a stored counter so that a demo can move. Read once, because
    /// `CompositionRoot.shared` is built once per launch: quitting and opening the app is what
    /// advances the shop, which is exactly the journey the bag and the waitlist are worth seeing on.
    private static func thisVisit() -> Int {
        let key = "demo.visit"
        let defaults = UserDefaults.standard
        let visit = defaults.integer(forKey: key) + 1
        defaults.set(visit, forKey: key)
        return visit
    }
}
