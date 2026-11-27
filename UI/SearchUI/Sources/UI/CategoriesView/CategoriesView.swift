import SwiftUI
import Product
import Tracking
import TrackingUI

/// The categories, with All Products at the top. Each row is placed at its position in the list —
/// All Products at 0, each category one below its place among the categories — and says where it
/// was when it is tapped or seen, so the screen that owns the list never has to count.
public struct CategoriesView: View {
    let categories: [ProductCategory]
    let onSelectAll: (TrackingContext) -> Void
    let onSelect: (ProductCategory, TrackingContext) -> Void
    let onSeeAll: (TrackingContext) -> Void
    let onSee: (ProductCategory, TrackingContext) -> Void

    public init(
        categories: [ProductCategory],
        onSelectAll: @escaping (TrackingContext) -> Void,
        onSelect: @escaping (ProductCategory, TrackingContext) -> Void,
        onSeeAll: @escaping (TrackingContext) -> Void,
        onSee: @escaping (ProductCategory, TrackingContext) -> Void
    ) {
        self.categories = categories
        self.onSelectAll = onSelectAll
        self.onSelect = onSelect
        self.onSeeAll = onSeeAll
        self.onSee = onSee
    }

    public var body: some View {
        List {
            TrackedRow(onTap: onSelectAll, onSeen: onSeeAll) {
                Text("All Products")
            }
            .trackingPosition(0)

            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                TrackedRow(onTap: { onSelect(category, $0) }, onSeen: { onSee(category, $0) }) {
                    Text(category.name)
                }
                .trackingPosition(index + 1)
            }
        }
        .listStyle(.plain)
        .trackingList(SearchTrackingPlan.categories)
    }
}
