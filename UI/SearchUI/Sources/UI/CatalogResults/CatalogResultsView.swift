import SwiftUI
import Product
import ProductUI

public struct CatalogResultsView: View {
    @StateObject private var viewModel: CatalogResultsViewModel
    let navigation: SearchNavigation
    let wishlistButton: (Int) -> AnyView
    let bagButton: (Product) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> CatalogResultsViewModel,
        navigation: SearchNavigation,
        wishlistButton: @escaping (Int) -> AnyView,
        bagButton: @escaping (Product) -> AnyView
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.navigation = navigation
        self.wishlistButton = wishlistButton
        self.bagButton = bagButton
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.results,
            isLoadingMore: viewModel.isLoadingMore,
            onSelect: { product in
                viewModel.didSelect(product)
                navigation.openProductDetails(product: product)
            },
            onReachEnd: {
                Task { await viewModel.loadMore() }
            },
            accessory: { product in wishlistButton(product.id) },
            leadingAccessory: { product in bagButton(product) }
        )
        .overlay {
            if viewModel.isLoading && viewModel.results.isEmpty {
                ProgressView()
            } else if !viewModel.isLoading, viewModel.results.isEmpty, let text = viewModel.emptySearchText {
                ContentUnavailableView.search(text: text)
            }
        }
        .navigationTitle(viewModel.title)
        .task {
            await viewModel.onAppear()
        }
    }
}
