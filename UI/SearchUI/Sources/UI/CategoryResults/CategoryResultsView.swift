import SwiftUI
import ProductUI

public struct CategoryResultsView: View {
    @StateObject private var viewModel: CategoryResultsViewModel
    let navigation: SearchNavigation
    let wishlistButton: (Int) -> AnyView

    public init(
        viewModel: @autoclosure @escaping () -> CategoryResultsViewModel,
        navigation: SearchNavigation,
        wishlistButton: @escaping (Int) -> AnyView
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
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
            }
        }
        .navigationTitle(viewModel.displayName)
        .task {
            await viewModel.onAppear()
        }
    }
}
