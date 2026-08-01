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
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded(let feed):
                feedView(feed)
            case .error:
                ContentUnavailableView {
                    Label("Nothing to Show", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("Check your signal and give it another go.")
                } actions: {
                    Button("Try Again") { viewModel.didTapRetry() }
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    private func feedView(_ feed: HomeFeed) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(feed.carousels) { carousel in
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
    }
}
