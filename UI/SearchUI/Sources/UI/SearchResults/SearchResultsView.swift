import SwiftUI
import ProductUI

public struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    let navigation: SearchNavigation
    let wishlistButton: (Int) -> AnyView

    public init(
        viewModel: SearchResultsViewModel,
        navigation: SearchNavigation,
        wishlistButton: @escaping (Int) -> AnyView
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
    }

    public var body: some View {
        ProductGridListView(
            products: viewModel.results,
            isLoadingMore: viewModel.isLoadingMore,
            onSelect: { product in
                viewModel.didSelect(product)
                navigation.openProductDetails(id: product.id)
            },
            onReachEnd: {
                Task { await viewModel.loadMore() }
            },
            accessory: { product in wishlistButton(product.id) }
        )
        .overlay {
            if viewModel.isLoading && viewModel.results.isEmpty {
                ProgressView()
            } else if !viewModel.isLoading && viewModel.results.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
        .navigationTitle(viewModel.query)
        .task {
            await viewModel.onAppear()
        }
    }
}
