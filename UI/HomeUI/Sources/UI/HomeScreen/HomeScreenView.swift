import SwiftUI
import Product

public struct HomeScreenView: View {
    @ObservedObject var viewModel: HomeScreenViewModel
    let navigation: HomeNavigation

    public init(viewModel: HomeScreenViewModel, navigation: HomeNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        List(viewModel.products) { product in
            Button {
                viewModel.didSelect(product)
            } label: {
                HStack {
                    AsyncImage(url: URL(string: product.thumbnail)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading) {
                        Text(product.title).font(.headline)
                        Text(product.price, format: .currency(code: "USD"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView()
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }
}
