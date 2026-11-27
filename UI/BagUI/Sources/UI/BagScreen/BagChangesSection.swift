import SwiftUI
import Product
import Tracking
import TrackingUI

/// What changed since the shopper last viewed their bag, above the bag itself. It is there to be
/// read and nothing else: the lines below it already show today's prices and what the shop has
/// left, so there is nothing here to accept, and nothing here stands between a shopper and the
/// checkout.
///
/// The one thing a row offers is a bell, on something that sold out — the only change a shopper can
/// wait out.
struct BagChangesSection: View {
    let viewModel: BagScreenViewModel

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: a bell this
    /// screen cannot name. `Component/StockAlert` and its buttons live outside this feature, so the
    /// app layer passes one in already built and BagUI stays unaware there is a stock alert domain.
    /// The erasure is what a boundary costs, not a shortcut around one.
    let stockAlertButton: (Product) -> AnyView

    var body: some View {
        Section {
            ForEach(Array(viewModel.changes.enumerated()), id: \.element.id) { index, row in
                TrackingContextReader { context in changeRow(row, context: context) }
                    .onImpression { viewModel.didSee(row, in: $0) }
                    .trackingPosition(index)
                    .trackingList(BagTrackingPlan.changes)
            }
        } header: {
            BagSectionHeader(
                title: "Changes since you last viewed",
                icon: "clock.arrow.circlepath",
                tint: .orange,
                description: "Your bag below is already up to date. This is what's different."
            ) {
                EmptyView()
            }
        }
    }

    /// One row for every change, so a shopper reads them the same way whatever happened: the
    /// product, then the one thing that is different about it.
    private func changeRow(_ row: BagChangeRow, context: TrackingContext) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                BagThumbnail(product: row.product)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.product?.title ?? " ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .redacted(reason: row.product == nil ? .placeholder : [])

                    switch row.says {
                    case .soldOut(let words), .howManyLeft(let words):
                        Text(words)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                    case .priceMoved(let move):
                        priceMove(move)
                    }
                }

                Spacer(minLength: 0)
            }
            /// The same target as a bag line: everything left of the accessory. A shopper reading
            /// that something got dearer wants to go and look at it.
            .contentShape(Rectangle())
            .onTapGesture { viewModel.didTapRow(row, in: context) }

            /// The bell is about a product, so it waits for the shop to say which one — the same
            /// moment the row's name stops being a placeholder.
            if case .soldOut = row.says, let product = row.product {
                stockAlertButton(product)
            }
        }
        .padding(.vertical, 6)
    }

    /// The old amount struck through and the new one coloured, because a shopper takes in "less
    /// than it was" faster than they read it. Down is the accent colour rather than green: green
    /// against red reads as a gain or a loss, and a cheaper price is neither — it is just better.
    ///
    /// Two amounts and an arrow sit on one line until a product is expensive enough that they do
    /// not. An amount that wraps is broken mid-number and has to be reassembled to be read, which
    /// is the one thing a price may never ask of anybody. So neither amount can wrap or truncate:
    /// when the line runs out they take a second one together, in the same order, still reading
    /// old-then-new.
    private func priceMove(_ move: BagChangeRow.PriceMove) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                oldAmount(move)
                direction(move)
                newAmount(move)
            }

            VStack(alignment: .leading, spacing: 2) {
                oldAmount(move)

                HStack(spacing: 6) {
                    direction(move)
                    newAmount(move)
                }
            }
        }
        .font(.subheadline)
        .monospacedDigit()
    }

    /// `fixedSize` is what makes the fallback happen. Left to itself a `Text` would rather wrap than
    /// report that it does not fit, so nothing above would ever measure as too wide.
    private func oldAmount(_ move: BagChangeRow.PriceMove) -> some View {
        Text(move.was)
            .strikethrough()
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
    }

    private func direction(_ move: BagChangeRow.PriceMove) -> some View {
        Image(systemName: move.isCheaper ? "arrow.down" : "arrow.up")
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint(move))
    }

    private func newAmount(_ move: BagChangeRow.PriceMove) -> some View {
        Text(move.now)
            .fontWeight(.semibold)
            .foregroundStyle(tint(move))
            .lineLimit(1)
            .fixedSize()
    }

    private func tint(_ move: BagChangeRow.PriceMove) -> Color {
        move.isCheaper ? Color.accentColor : .orange
    }
}
