import Product
import Tracking

/// The tracking plan for Search: its two screens, what can be touched on them, and the lists they
/// draw — named once.
///
/// Evans, *Domain-Driven Design* (2003), Ch. 2 — Ubiquitous Language: these names are what a
/// report is read in, and changing one splits that report in two. They change here or nowhere.
///
/// Typing into the field does not change the screen. The categories, the recent searches and the
/// suggestions are three lists on the one Search screen, and the field is what decides which of
/// them is showing.
public enum SearchTrackingPlan {
    public static let screen = "search"
    public static let resultsScreen = "search_results"

    static let categories = TrackingContext.List(id: "search_categories", name: "Categories")
    static let history = TrackingContext.List(id: "search_history", name: "Recent Searches")
    static let suggestions = TrackingContext.List(id: "search_suggestions", name: "Suggestions")

    static let categoryRow = "category"
    static let recentSearchRow = "recent_search"
    static let suggestionRow = "suggestion"
    static let clearHistory = "clear_history"

    /// All Products sits at the top of the categories, so it is the first row of that list and
    /// is reported as one — at position 0, with every category one below its place among them.
    static let allProducts = TrackedItem.content(id: "all", name: "All Products")

    static func item(_ category: ProductCategory) -> TrackedItem {
        .content(id: category.id.rawValue, name: category.name)
    }

    /// A recent search is about what was searched for — its words are its identity.
    static func item(_ term: SearchTerm) -> TrackedItem {
        .content(id: term.text, name: term.text)
    }

    /// One list per thing the results are of: all of the catalog, one category, or a search. Every
    /// search shares one id so their positions can be compared, and the words go in the name.
    static func results(_ filter: CatalogFilter, title: String) -> TrackingContext.List {
        switch filter {
        case .all: TrackingContext.List(id: "search_results_all", name: title)
        case .category(let category): TrackingContext.List(id: "search_results_\(category.id.rawValue)", name: title)
        case .search: TrackingContext.List(id: "search_results_search", name: title)
        }
    }
}
