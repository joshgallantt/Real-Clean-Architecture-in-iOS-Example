import SwiftUI
import Home
import Product
import Tracking
import TrackingUI

public struct HomeScreenView: View {
    @Environment(\.trackingContext) private var trackingContext
    let viewModel: HomeScreenViewModel
    let wishlistButton: (Product) -> AnyView
    let bagButton: (Product) -> AnyView

    public init(
        viewModel: HomeScreenViewModel,
        wishlistButton: @escaping (Product) -> AnyView,
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
                    Button("Try Again") { viewModel.didTapRetry(in: trackingContext) }
                }
            }
        }
        .onScreenAppear { viewModel.didAppear(in: $0) }
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
                        onSelect: { viewModel.didSelect($0, in: $1) },
                        onSeen: { viewModel.didSee($0, in: $1) },
                        onViewAll: { viewModel.didTapViewAll(for: carousel, in: $0) },
                        accessory: { product in wishlistButton(product) },
                        leadingAccessory: { product in bagButton(product) }
                    )
                    .trackingList(HomeTrackingPlan.list(carousel))
                }
            }
            .padding(.vertical)
        }
    }
}
