import SwiftUI
import UIKit
import Product

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    let navigation: BagNavigation

    public init(viewModel: BagScreenViewModel, navigation: BagNavigation) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        Group {
            if viewModel.products.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.products) { product in
                        row(for: product)
                            .swipeActions {
                                Button("Remove", role: .destructive) {
                                    viewModel.didSwipeToDelete(productId: product.id)
                                }
                            }
                            .onAppear {
                                if product.id == viewModel.products.last?.id {
                                    viewModel.onReachEnd()
                                }
                            }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    totalFooter
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private func row(for product: Product) -> some View {
        HStack(spacing: 12) {
            Button {
                navigation.openProductDetails(product: product)
            } label: {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: product.thumbnail)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                        Text(product.price, format: .currency(code: "USD"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Stepper(
                value: Binding(
                    get: { viewModel.quantities[product.id] ?? 1 },
                    set: {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.didChangeQuantity(productId: product.id, quantity: $0)
                    }
                ),
                in: 1...99
            ) {
                Text("\(viewModel.quantities[product.id] ?? 1)")
                    .font(.subheadline.weight(.medium))
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
    }

    private var totalFooter: some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            Text(viewModel.total, format: .currency(code: "USD"))
                .font(.headline)
        }
        .padding()
        .background(.bar)
    }
}
