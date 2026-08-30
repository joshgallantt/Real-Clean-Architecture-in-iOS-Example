import Combine
import Foundation
import Home
import Product

@MainActor
/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: state and behaviour
/// live here so the view has nothing in it worth testing. It depends on use case protocols alone —
/// never a repository, a store or a data source.
///
/// Martin, Ch. 10 — Interface Segregation Principle: it is injected the one capability it calls.
/// What a category needs to earn a carousel, and how many carousels Home draws, are
/// `DrawHomeFeedUseCase`'s business, not this screen's.
public final class HomeScreenViewModel: ObservableObject {
    /// The work the last interaction started.
    ///
    /// SwiftUI calls a button's action and `onAppear` synchronously, so anything
    /// that has to be awaited starts a `Task` and returns. Keeping the handle is
    /// what lets a test wait for that work rather than guess at how long it
    /// takes — and what would let the screen cancel it on disappear.
    public private(set) var inFlight: Task<Void, Never>?

    @Published private(set) var state: HomeScreenState = .loading

    private let drawHomeFeed: DrawHomeFeedUseCase
    private let navigation: HomeNavigation

    public init(drawHomeFeed: DrawHomeFeedUseCase, navigation: HomeNavigation) {
        self.drawHomeFeed = drawHomeFeed
        self.navigation = navigation
    }

    func onAppear() async {
        if case .loaded = state { return }
        await load()
    }

    func didTapRetry() {
        inFlight = Task { await load() }
    }

    private func load() async {
        state = .loading

        switch await drawHomeFeed() {
        case .success(let feed):
            state = .loaded(feed)
        case .failure:
            state = .error
        }
    }

    func didSelect(_ product: Product) {
        navigation.openProductDetails(product: product)
    }

    func didTapViewAll(for carousel: HomeCarousel) {
        navigation.openCatalog(filter: .category(carousel.category))
    }
}
