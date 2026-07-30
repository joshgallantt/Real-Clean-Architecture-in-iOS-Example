/// Martin, *Clean Architecture* (2017), Ch. 8 — Open/Closed Principle: a demo is added by writing a
/// new `Catalog`, not by editing the app around it. The exemplar stays the thing worth reading, and
/// a demo cannot leak into it.
///
/// Martin, Ch. 26 — The Main Component: which catalog the app runs on is chosen at one line, in the
/// only layer allowed to choose concrete types. Both arrangements compile at all times, so a demo
/// cannot rot and switching one on is never a matter of uncommenting code.
///
/// To run it, set `isOn` to `true` and rebuild. Add three or four things to the bag with the demo
/// off first: prices will have moved, some lines will be short, some will have gone. Tap Okay on
/// one and it stays; tap Remove on another and it goes with its notice. Relaunch and the notices a
/// shopper never read are still waiting, because they are kept with the bag.
enum Demo {
    static let isOn = false

    /// A shop that has changed its mind since the shopper last looked: the real one, with its
    /// answers meddled with on the way past — so the demo cannot drift from what the app talks to.
    ///
    /// `browseCategories` is passed through untouched, because how the shop divides up what it
    /// sells is not what the demo is about.
    static func shopThatChangesItsMind() -> Catalog {
        let real = Catalog.live()
        return Catalog(
            browseCatalog: DemoBrowseCatalogUseCase(wrapped: real.browseCatalog),
            lookUpProducts: DemoLookUpProductsUseCase(wrapped: real.lookUpProducts),
            viewProduct: DemoViewProductUseCase(wrapped: real.viewProduct),
            browseCategories: real.browseCategories
        )
    }
}
