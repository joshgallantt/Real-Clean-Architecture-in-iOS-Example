import SwiftUI
import Product
import ProductUI

/// What a carousel's View All opens: the same products, all of them, in the grid every other
/// full list in this app uses. It is one screen rather than two because the lists differ in their
/// title and their empty state and in nothing else.
public struct SavedProductsListView: View {
    /// Owned, not observed. Unlike the tab's own screen — built once at startup and held — this is
    /// built by `makeView()` every time the navigation stack re-evaluates. Observing a view model
    /// handed in fresh each render would reset the list and re-ask the shop on every redraw.
    @StateObject private var viewModel: SavedProductsViewModel

    let title: String
    let emptyTitle: String
    let emptyIcon: String
    let emptyMessage: String
    let onSelect: (Product) -> Void
    let accessory: (Product) -> AnyView
    let leadingAccessory: (Product) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> SavedProductsViewModel,
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
            isLoadingMore: viewModel.isLoadingMore,
            onSelect: onSelect,
            onReachEnd: { viewModel.onReachEnd() },
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
