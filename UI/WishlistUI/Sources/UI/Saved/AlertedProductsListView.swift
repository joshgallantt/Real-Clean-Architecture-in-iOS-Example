import SwiftUI
import Product
import ProductUI

/// What a stock-alert carousel's View All opens: the same products, all of them, in the grid every
/// other full list in this app uses.
///
/// Its own screen rather than a second use of `SavedProductsListView`, because the two are fed by
/// genuinely different things — a wishlist is a list of ids to fill in and page through, and these
/// are answered whole by a use case. Only the grid is shared, which is the part that is the same.
public struct AlertedProductsListView: View {
    /// Owned, not observed. `makeView()` builds it afresh on every navigation re-evaluation, and an
    /// observed one handed in each render would reload on every redraw.
    @StateObject private var viewModel: AlertedProductsViewModel

    let title: String
    let emptyTitle: String
    let emptyIcon: String
    let emptyMessage: String
    let onSelect: (Product) -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> AlertedProductsViewModel,
        title: String,
        emptyTitle: String,
        emptyIcon: String,
        emptyMessage: String,
        onSelect: @escaping (Product) -> Void,
        accessory: @escaping (Product) -> AnyView,
        leadingAccessory: @escaping (Product) -> AnyView
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.title = title
        self.emptyTitle = emptyTitle
        self.emptyIcon = emptyIcon
        self.emptyMessage = emptyMessage
        self.onSelect = onSelect
        self.accessory = accessory
        self.leadingAccessory = leadingAccessory
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.products,
            isLoadingMore: false,
            onSelect: onSelect,
            onReachEnd: {},
            accessory: accessory,
            leadingAccessory: leadingAccessory
        )
        .overlay {
            if viewModel.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon,
                    description: Text(emptyMessage)
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { viewModel.onAppear() }
    }
}
