import SwiftUI
import Product
import ProductUI
import Tracking
import TrackingUI

public struct CatalogResultsView: View {
    @Environment(\.trackingContext) private var trackingContext
    @State private var viewModel: CatalogResultsViewModel
    let navigation: SearchNavigation
    let wishlistButton: (Product) -> AnyView
    let bagButton: (Product) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> CatalogResultsViewModel,
        navigation: SearchNavigation,
        wishlistButton: @escaping (Product) -> AnyView,
        bagButton: @escaping (Product) -> AnyView
    ) {
        self._viewModel = State(wrappedValue: viewModel())
        self.navigation = navigation
        self.wishlistButton = wishlistButton
        self.bagButton = bagButton
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.results,
            isLoadingMore: viewModel.isLoadingMore,
            onSelect: { product, context in
                viewModel.didSelect(product, in: context)
                navigation.openProductDetails(product: product)
            },
            onSeen: { viewModel.didSee($0, in: $1) },
            onCardAppear: { viewModel.didLayOut($0, in: trackingContext) },
            accessory: { product in wishlistButton(product) },
            leadingAccessory: { product in bagButton(product) }
        )
        .trackingList(viewModel.list)
        .overlay {
            if viewModel.isLoading && viewModel.results.isEmpty {
                ProgressView()
            } else if !viewModel.isLoading, viewModel.results.isEmpty, let text = viewModel.emptySearchText {
                ContentUnavailableView.search(text: text)
            }
        }
        .navigationTitle(viewModel.title)
        .onScreenAppear { viewModel.didAppear(in: $0) }
        .task {
            await viewModel.onAppear(in: trackingContext)
        }
    }
}
