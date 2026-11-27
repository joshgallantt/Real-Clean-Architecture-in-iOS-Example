import Home
import Product
import Tracking

/// The tracking plan for Home: its screen, what can be touched on it, and the lists it draws —
/// named once, so a report and the code agree on what everything is called.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: these names are what a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
///
/// Public for the screen name alone: `HomeUIDI` declares it above the screen it builds, so
/// everything drawn on Home — the cards, and the hearts and bag buttons on them — reads it.
public enum HomeTrackingPlan {
    public static let screen = "home"

    static let viewAll = "view_all"
    static let retry = "retry"

    /// One list per carousel, keyed by category so a report can compare carousels across draws —
    /// the feed shuffles which categories it shows, but Beauty is Beauty whichever slot it lands in.
    static func list(_ carousel: HomeCarousel) -> TrackingContext.List {
        TrackingContext.List(id: "home_carousel_\(carousel.category.id.rawValue)", name: carousel.category.name)
    }

    /// What View All is about: the category it opens.
    static func item(_ category: ProductCategory) -> TrackedItem {
        .content(id: category.id.rawValue, name: category.name)
    }
}
