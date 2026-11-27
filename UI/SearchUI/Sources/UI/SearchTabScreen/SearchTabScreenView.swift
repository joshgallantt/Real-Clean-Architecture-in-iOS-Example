import SwiftUI
import Product
import Tracking
import TrackingUI

public struct SearchTabScreenView: View {
    @Environment(\.trackingContext) private var trackingContext
    @Bindable var viewModel: SearchTabScreenViewModel
    let searchingViewModel: SearchingViewModel
    let navigation: SearchNavigation
    @FocusState private var isFocused: Bool

    public init(
        viewModel: SearchTabScreenViewModel,
        searchingViewModel: SearchingViewModel,
        navigation: SearchNavigation
    ) {
        self.viewModel = viewModel
        self.searchingViewModel = searchingViewModel
        self.navigation = navigation
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search products", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)
                .padding()
                .focused($isFocused)
                .onSubmit {
                    commitSearch(viewModel.query)
                }
                .onChange(of: viewModel.query) {
                    searchingViewModel.queryChanged(viewModel.query)
                }

            if viewModel.isSearchActive {
                SearchingView(
                    viewModel: searchingViewModel,
                    onSelectHistory: { term, context in
                        viewModel.query = term.text
                        isFocused = false
                        viewModel.didSubmitSearch(term, in: context)
                        navigation.openCatalog(filter: .search(term))
                    },
                    onSelectSuggestion: { product in
                        isFocused = false
                        navigation.openProductDetails(product: product)
                    }
                )
            } else {
                CategoriesView(
                    categories: viewModel.categories,
                    onSelectAll: { context in
                        viewModel.didSelectAllProducts(in: context)
                        navigation.openCatalog(filter: .all)
                    },
                    onSelect: { category, context in
                        viewModel.didSelectCategory(category, in: context)
                        navigation.openCatalog(filter: .category(category))
                    },
                    onSeeAll: { viewModel.didSeeAllProducts(in: $0) },
                    onSee: { viewModel.didSee($0, in: $1) }
                )
            }
        }
        .onChange(of: isFocused) {
            viewModel.isSearchActive = isFocused
            if !isFocused {
                viewModel.query = ""
            }
        }
        .onScreenAppear { viewModel.didAppear(in: $0) }
        .task {
            await viewModel.onAppear(in: trackingContext)
        }
    }

    /// Evans, *Domain-Driven Design* (2003) — Value Objects: whether what the shopper typed is a
    /// search at all is `SearchTerm`'s to answer. A view that trims first is a second definition of
    /// the same rule, and that is how the search that was recorded and the search that was run came
    /// to disagree.
    private func commitSearch(_ typed: String) {
        guard let term = SearchTerm(typed) else { return }
        isFocused = false
        viewModel.didSubmitSearch(term, in: trackingContext)
        navigation.openCatalog(filter: .search(term))
    }
}
