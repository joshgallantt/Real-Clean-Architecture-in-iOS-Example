import SwiftUI
import Product
import Tracking
import TrackingUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: a heading, a row of
/// cards, and a way to see the rest. It decides nothing — what it is called, what it holds and
/// where View All goes all arrive as arguments, which is what lets one section be every list a
/// shopper keeps, whichever feature keeps it.
///
/// Martin, Ch. 13 — Component Cohesion: it sits beside `ProductCardRowView` because it is that row
/// with a heading on it. The faves and the stock alerts are drawn by different features, and a
/// section that lived in either would make the other depend on a feature to draw a heading.
public struct ProductCarouselSection: View {
    /// What the section does when it holds nothing.
    public enum WhenEmpty {
        /// Not drawn at all — a list that only exists when there is something on it.
        case hidden
        /// Drawn, with a sentence where the cards would be.
        case explained(String)
    }

    @State private var isConfirmingClear = false
    @Environment(\.trackingContext) private var trackingContext

    /// Products and a count, not a view model. A wishlist is a list of ids that has to be filled in
    /// and paged; the stock alerts are answered whole by a use case. Typing this to either would
    /// make the other one wrong, and a row of cards has no business knowing the difference.
    private let products: [Product]
    private let total: Int
    private let onClear: (TrackingContext) -> Void

    private let title: String
    private let icon: String
    private let tint: Color
    private let description: String
    private let whenEmpty: WhenEmpty
    private let onSelect: (Product, TrackingContext) -> Void
    private let onSeen: (Product, TrackingContext) -> Void
    private let onViewAll: (TrackingContext) -> Void
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    /// A row is a sample, not the list. Ten is far more than anybody scrolls sideways through, and
    /// View All is right there for the rest — so a screen of sections stays a summary rather than a
    /// stack of lists a shopper has to get past.
    private let atMost = 10

    public init(
        products: [Product],
        total: Int,
        onClear: @escaping (TrackingContext) -> Void,
        title: String,
        icon: String,
        tint: Color,
        description: String,
        whenEmpty: WhenEmpty,
        onSelect: @escaping (Product, TrackingContext) -> Void,
        onSeen: @escaping (Product, TrackingContext) -> Void,
        onViewAll: @escaping (TrackingContext) -> Void,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self.products = products
        self.total = total
        self.onClear = onClear
        self.title = title
        self.icon = icon
        self.tint = tint
        self.description = description
        self.whenEmpty = whenEmpty
        self.onSelect = onSelect
        self.onSeen = onSeen
        self.onViewAll = onViewAll
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    @ViewBuilder
    public var body: some View {
        if isDrawn {
            section
        }
    }

    private var isDrawn: Bool {
        if products.isEmpty, case .hidden = whenEmpty { false } else { true }
    }

    private var section: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProductSectionHeader(title: title, icon: icon, tint: tint, description: description) {
                /// Nothing to offer about an empty list: neither seeing the rest of it nor emptying
                /// it means anything, and two disabled buttons say less than no buttons.
                if total > 0 {
                    HStack(spacing: 12) {
                        Button("View All (\(total))") { onViewAll(trackingContext) }

                        /// Red, because it is the only thing in this heading that takes something
                        /// away — and asked about first, because there is no undo behind it.
                        Button("Clear", role: .destructive) { isConfirmingClear = true }
                            .foregroundStyle(.red)
                    }
                }
            }

            if products.isEmpty, case .explained(let message) = whenEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                ProductCardRowView(
                    products: Array(products.prefix(atMost)),
                    onSelect: onSelect,
                    onSeen: onSeen,
                    accessory: accessory,
                    leadingAccessory: leadingAccessory
                )
            }
        }
        /// On the section rather than offered as something the caller must remember to attach.
        /// A Clear whose confirmation can be left off is a Clear that one day deletes without
        /// asking.
        .confirmationDialog(
            "Clear \(title)?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear \(title)", role: .destructive) { onClear(trackingContext) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This empties \(title). It cannot be undone.")
        }
    }
}
