import SwiftUI
import Product
import Tracking
import TrackingUI

/// One card in a row or a grid, saying where it is when it is tapped or seen. The position is set
/// on it by the row that placed it and the list by whoever owns the row, so the card itself knows
/// neither — and nor does the heart or the bag button drawn on it, which read the same context.
struct TrackedProductCard: View {
    @Environment(\.trackingContext) private var trackingContext

    let product: Product
    let onSelect: (Product, TrackingContext) -> Void
    let onSeen: (Product, TrackingContext) -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    var body: some View {
        Button {
            onSelect(product, trackingContext)
        } label: {
            ProductCardView(
                product: product,
                accessory: { accessory(product) },
                leadingAccessory: { leadingAccessory(product) }
            )
        }
        .buttonStyle(.plain)
        .onImpression { onSeen(product, $0) }
    }
}
