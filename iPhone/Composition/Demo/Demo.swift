/// Martin, *Clean Architecture* (2017), Ch. 8 — Open/Closed Principle: a demo is added by writing a
/// new `Catalog`, not by editing the app around it. The exemplar stays the thing worth reading, and
/// a demo cannot leak into it.
///
/// Martin, Ch. 26 — The Main Component: which catalog the app runs on is chosen at one line, in the
/// only layer allowed to choose concrete types. Both arrangements compile at all times, so a demo
/// cannot rot and switching one on is never a matter of uncommenting code.
///
/// To run it, set `isOn` to `true` and rebuild. Add three or four things to the bag, then open the
/// Bag tab: prices have moved, some lines are short, some have gone. Tap Okay on one and it stays;
/// tap Remove on another and it goes with its notice. Relaunch and the notices a shopper never read
/// are still waiting, because they are kept with the bag.
enum Demo {
    static let isOn = true

    /// A shop that has changed its mind since the shopper last looked.
    ///
    /// Only `lookUpProducts` is meddled with, and that is the whole trick. Browsing is what the shop
    /// is selling *now*; `lookUpProducts` is what it says about things the shopper already holds.
    /// Meddling both meant a shopper added an already-moved price and the bag was then told that
    /// same moved price — nothing differed, so nothing was reported, and the demo could only be seen
    /// by adding items with it switched off and rebuilding with it on.
    ///
    /// Meddling the one path the bag reads makes the difference appear in a single run, and is the
    /// more honest story besides: the bag is the only thing here looking backwards.
    static func shopThatChangesItsMind() -> Catalog {
        let real = Catalog.live()
        return Catalog(
            browseCatalog: real.browseCatalog,
            lookUpProducts: DemoLookUpProductsUseCase(wrapped: real.lookUpProducts),
            viewProduct: real.viewProduct,
            browseCategories: real.browseCategories
        )
    }
}
