import SwiftUI
import Product
import ProductUI
import Tracking
import TrackingUI

/// What the stock alerts row's View All opens: the same products, all of them, in the grid every
/// other full list in this app uses.
public struct StockAlertProductsListView: View {
    @Environment(\.trackingContext) private var trackingContext
    /// Owned, not observed. `makeView()` builds it afresh on every navigation re-evaluation, and an
    /// observed one handed in each render would reload on every redraw.
    @State private var viewModel: StockAlertProductsViewModel

    let emptyTitle: String
    let emptyIcon: String
    let emptyMessage: String
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> StockAlertProductsViewModel,
        emptyTitle: String,
        emptyIcon: String,
        emptyMessage: String,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self._viewModel = State(wrappedValue: viewModel())
        self.emptyTitle = emptyTitle
        self.emptyIcon = emptyIcon
        self.emptyMessage = emptyMessage
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.products,
            isLoadingMore: false,
            onSelect: { viewModel.didSelect($0, in: $1) },
            onSeen: { viewModel.didSee($0, in: $1) },
            onCardAppear: { _ in },
            accessory: accessory,
            leadingAccessory: leadingAccessory
        )
        .trackingList(StockAlertTrackingPlan.list)
        .overlay {
            if viewModel.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon,
                    description: Text(emptyMessage)
                )
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .onScreenAppear { viewModel.didAppear(in: $0) }
        .task { await viewModel.onAppear(in: trackingContext) }
    }
}
