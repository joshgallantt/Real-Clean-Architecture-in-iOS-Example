import SwiftUI
import Order

public struct OrderHistoryScreen: View {
    @StateObject private var viewModel: OrderHistoryViewModel

    public init(viewModel: @autoclosure @escaping () -> OrderHistoryViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No Orders Yet",
                    systemImage: "shippingbox",
                    description: Text("Anything you buy will show up here.")
                )
            } else {
                List(viewModel.orders) { order in
                    row(order)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Your Orders")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// What an order was, in the three facts a shopper is looking for when they come back to it:
    /// when, how much, and how many things. What those things are *called* is the catalog's to say
    /// and may no longer be true, so it is not said here.
    private func row(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.reference)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Spacer()
                Text(order.total?.formatted() ?? "")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                Text(order.placedOnLabel)
                Text("·")
                Text(order.itemCountSummary)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
