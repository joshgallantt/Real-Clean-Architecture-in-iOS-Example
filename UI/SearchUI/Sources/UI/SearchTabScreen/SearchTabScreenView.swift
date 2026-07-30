import SwiftUI
import Product

public struct SearchTabScreenView: View {
    @ObservedObject var viewModel: SearchTabScreenViewModel
    @ObservedObject var searchingViewModel: SearchingViewModel
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
                    onSelectHistory: { term in
                        viewModel.query = term.text
                        isFocused = false
                        viewModel.didSubmitSearch(term)
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
                    onSelectAll: { navigation.openCatalog(filter: .all) },
                    onSelect: { category in
                        viewModel.didSelectCategory(category)
                        navigation.openCatalog(filter: .category(category))
                    }
                )
            }
        }
        .onChange(of: isFocused) {
            viewModel.isSearchActive = isFocused
            if !isFocused {
                viewModel.query = ""
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    /// Evans, *Domain-Driven Design* (2003) — Value Objects: whether what the shopper typed is a
    /// search at all is `SearchTerm`'s to answer. A view that trims first is a second definition of
    /// the same rule, and that is how the search that was recorded and the search that was run came
    /// to disagree.
    private func commitSearch(_ typed: String) {
        guard let term = SearchTerm(typed) else { return }
        isFocused = false
        viewModel.didSubmitSearch(term)
        navigation.openCatalog(filter: .search(term))
    }
}
