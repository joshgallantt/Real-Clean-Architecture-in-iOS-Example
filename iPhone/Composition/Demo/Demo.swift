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
/// In the catalog, roughly one product in ten has sold out: its card carries a bell instead of a
/// bag button, and its page offers Notify Me instead of Add to Bag. Tap the bell and it fills in —
/// the same product, on any screen showing it, is the same product.
///
/// Then add half a dozen things to the bag, taking two of at least one of them, and open the Bag
/// tab. Prices have moved both ways, a line is short, and some have gone — out of stock in one
/// section and stopped-selling in another. Tap Okay on one and it stays; tap the remove button on a
/// dearer one and it goes with its notice. Relaunch and the notices a shopper never read are still
/// waiting, because they are kept with the bag.
enum Demo {
    static let isOn = true

    /// A shop that has changed its mind since the shopper last looked.
    ///
    /// Every read the app makes about a product is decorated, so what the demo decides about one is
    /// what every screen shows. What the two decorators say differs, though, and deliberately:
    /// browsing is what the shop is selling *now*, while `lookUpProducts` is what it says about
    /// things the shopper is already holding.
    ///
    /// Telling both the same story cost the demo its point. A price already moved when it was added
    /// is the price the bag is later told, so nothing differs and nothing is reported; a product
    /// already sold out cannot be put in a bag at all. The moods that only `lookUpProducts` hears
    /// are the ones that need a before and an after to be visible — see `DemoShop.Mood`.
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
