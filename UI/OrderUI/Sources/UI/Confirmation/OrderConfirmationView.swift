import SwiftUI

/// Martin, *Clean Architecture* (2017), Ch. 23 — Presenters and Humble Objects: it is handed the
/// order that was placed and renders it. There is nothing to fetch and nothing that can fail —
/// by the time this is on screen the money has moved and the order exists.
///
/// It reads nothing from the catalog, so it says what was bought rather than what those products
/// are called today. That is not a shortcut: an order is a record of a payment, and a confirmation
/// that went looking for product names would break for anything since withdrawn.
public struct OrderConfirmationView: View {
    private let order: OrderSummary
    private let done: () -> Void

    public init(order: OrderSummary, done: @escaping () -> Void) {
        self.order = order
        self.done = done
    }

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .padding(.top, 48)

            VStack(spacing: 6) {
                Text("Nice One")
                    .font(.title2.bold())
                Text("That's yours. We're getting it ready.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                row("Order", order.reference)
                Divider()
                row("Items", order.itemCount)
                Divider()
                row("Total", order.total)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            Spacer()

            Button("Done", action: done)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding()
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
