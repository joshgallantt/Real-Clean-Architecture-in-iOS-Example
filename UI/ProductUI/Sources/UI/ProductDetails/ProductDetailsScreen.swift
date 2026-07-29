import SwiftUI
import Product
import Kingfisher

public struct ProductDetailsScreen: View {
    @StateObject private var viewModel: ProductDetailsViewModel
    private let actionButton: (Product) -> AnyView
    private let wishlistButton: AnyView

    public init(
        viewModel: @autoclosure @escaping () -> ProductDetailsViewModel,
        actionButton: @escaping (Product) -> AnyView = { _ in AnyView(EmptyView()) },
        wishlistButton: AnyView = AnyView(EmptyView())
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.actionButton = actionButton
        self.wishlistButton = wishlistButton
    }

    public var body: some View {
        ScrollView {
            if let product = viewModel.product {
                content(for: product)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.loadFailed {
                ContentUnavailableView(
                    "Product Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This product couldn't be loaded.")
                )
            }
        }
        .navigationTitle(viewModel.product?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.onAppear()
        }
    }

    @ViewBuilder
    private func content(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            KFImage(URL(string: product.thumbnail))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(product.title)
                        .font(.title2.bold())
                }
                Spacer()
                wishlistButton
            }

            HStack(spacing: 16) {
                Text(product.price, format: .currency(code: "USD"))
                    .font(.title3.weight(.semibold))
                Label(String(format: "%.1f", product.rating), systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(product.stock > 0 ? "In stock" : "Out of stock")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(product.stock > 0 ? .green : .red)
            }

            actionButton(product)

            Text(product.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
