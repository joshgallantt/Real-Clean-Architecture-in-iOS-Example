import SwiftUI
import Product

public struct HomeScreenView: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    let wishlistButton: (ProductID) -> AnyView
    let bagButton: (Product) -> AnyView

    public init(
        viewModel: HomeScreenViewModel,
        wishlistButton: @escaping (ProductID) -> AnyView,
        bagButton: @escaping (Product) -> AnyView
    ) {
        self.viewModel = viewModel
        self.wishlistButton = wishlistButton
        self.bagButton = bagButton
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.carousels) { carousel in
                    HomeCarouselView(
                        carousel: carousel,
                        onSelect: { viewModel.didSelect($0) },
                        onViewAll: { viewModel.didTapViewAll(for: carousel) },
                        accessory: { product in wishlistButton(product.id) },
                        leadingAccessory: { product in bagButton(product) }
                    )
                }
            }
            .padding(.vertical)
        }
        .overlay {
            if viewModel.isLoading && viewModel.carousels.isEmpty {
                ProgressView()
            } else if viewModel.isEmpty {
                ContentUnavailableView("Nothing Here Yet", systemImage: "bag")
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }
}
