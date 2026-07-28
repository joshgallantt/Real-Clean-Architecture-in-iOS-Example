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
                    onSelectHistory: { query in
                        viewModel.query = query
                        commitSearch(query)
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

    private func commitSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isFocused = false
        viewModel.didSubmitSearch(trimmed)
        navigation.openCatalog(filter: .search(trimmed))
    }
}
