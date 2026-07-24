import SwiftUI
import Product

public struct SearchResultsView: View {
    @ObservedObject var viewModel: SearchResultsViewModel
    let navigation: SearchNavigation

    public init(viewModel: SearchResultsViewModel, navigation: SearchNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        List(viewModel.results) { product in
            Button {
                viewModel.didSelect(product)
            } label: {
                VStack(alignment: .leading) {
                    Text(product.title).font(.headline)
                    Text(product.price, format: .currency(code: "USD"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
