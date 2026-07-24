import SwiftUI
import Product

public struct CategoryResultsView: View {
    @ObservedObject var viewModel: CategoryResultsViewModel
    let navigation: SearchNavigation

    public init(viewModel: CategoryResultsViewModel, navigation: SearchNavigation) {
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
            }
        }
        .navigationTitle(viewModel.displayName)
        .task {
            await viewModel.onAppear()
        }
    }
}
