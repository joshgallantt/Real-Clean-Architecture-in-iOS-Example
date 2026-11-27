import SwiftUI
import Product
import ProductUI
import Tracking
import TrackingUI

/// The shopper's stock alerts as another screen shows them: a row of what they asked to be told
/// about, the ones that are back first. It shows a handful, offers the rest, and can be emptied in
/// one go.
///
/// It is not drawn while there is nothing on it, so a shopper with no alerts sees no trace of this
/// on the screen that hosts it.
public struct StockAlertSectionView: View {
    @Environment(\.trackingContext) private var trackingContext

    private let viewModel: StockAlertProductsViewModel

    /// What each card offers. The trailing one clears the alert, and the leading one buys, where
    /// buying is possible.
    private let accessory: (Product) -> AnyView
    private let leadingAccessory: (Product) -> AnyView

    /// The room left under the row when it is drawn. Under it rather than left to the host's own
    /// spacing, so a row that is not drawn leaves no gap behind where it would have been.
    private let roomBelow: CGFloat = 28

    public init(
        viewModel: StockAlertProductsViewModel,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self.viewModel = viewModel
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        /// The stack is what the load hangs from: it is there whether or not the row is, so the
        /// first load can happen while there is still nothing to draw.
        VStack(alignment: .leading, spacing: 0) {
            ProductCarouselSection(
                products: viewModel.products,
                total: viewModel.count,
                onClear: { viewModel.didConfirmClear(in: $0) },
                title: viewModel.title,
                icon: "bell.fill",
                tint: .orange,
                description: "Sold out when you asked. We'll show you the moment they're back.",
                whenEmpty: .hidden,
                onSelect: { viewModel.didSelect($0, in: $1) },
                onSeen: { viewModel.didSee($0, in: $1) },
                onViewAll: { viewModel.didTapViewAll(in: $0) },
                accessory: accessory,
                leadingAccessory: leadingAccessory
            )
            .trackingList(StockAlertTrackingPlan.list)
            .padding(.bottom, roomBelow)
        }
        .task { await viewModel.onAppear(in: trackingContext) }
    }
}
