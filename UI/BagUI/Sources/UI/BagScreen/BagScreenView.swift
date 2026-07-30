import SwiftUI
import UIKit
import Kingfisher
import Product

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    @State private var isConfirmingRemoveAll = false

    let navigation: BagNavigation

    /// Martin, *Clean Architecture* (2017), Ch. 11 — Dependency Inversion Principle: a bell this
    /// screen cannot name. `Component/StockAlert` and its buttons live outside this feature, so the
    /// app layer passes one in already built and BagUI stays unaware there is a stock alert domain.
    /// The erasure is what a boundary costs, not a shortcut around one.
    ///
    /// No default. One of these used to be a wishlist button that nothing rendered, and a default
    /// `EmptyView()` is exactly why nobody noticed.
    let stockAlertButton: (ProductID) -> AnyView

    public init(
        viewModel: BagScreenViewModel,
        navigation: BagNavigation,
        stockAlertButton: @escaping (ProductID) -> AnyView
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.stockAlertButton = stockAlertButton
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty && !viewModel.hasNews {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    if !viewModel.discontinuedRows.isEmpty { discontinuedSection }
                    if !viewModel.outOfStockRows.isEmpty { outOfStockSection }
                    if !viewModel.shortageRows.isEmpty { shortageSection }
                    if !viewModel.priceIncreaseRows.isEmpty { priceIncreaseSection }
                    if !viewModel.priceDecreaseRows.isEmpty { priceDecreaseSection }
                    if !viewModel.isEmpty { bagSection }
                }
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.isEmpty { totalFooter }
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $isConfirmingRemoveAll,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) { viewModel.didRemoveEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This empties your bag. It cannot be undone.")
        }
    }
    
    // MARK: - Gone for good

    /// No bell, because there is nothing to wait for. Nothing else either: every action this app
    /// has is a way of getting one of these eventually, and offering any of them here would be
    /// offering something the shop cannot honour. So the row says what it was and stops.
    private var discontinuedSection: some View {
        Section {
            ForEach(viewModel.discontinuedRows) { row in
                noticeRow(row, accessory: { EmptyView() })
            }
        } header: {
            sectionHeader(
                "No Longer Available",
                icon: "xmark.circle",
                tint: .secondary,
                description: "Discontinued. Sad - yes, but we thought you should know."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.discontinuedRows) }
            }
        }
    }

    // MARK: - Gone, but coming back

    private var outOfStockSection: some View {
        Section {
            ForEach(viewModel.outOfStockRows) { row in
                noticeRow(row, accessory: { stockAlertButton(row.id) })
            }
        } header: {
            sectionHeader(
                "Out Of Stock",
                icon: "shippingbox",
                tint: .orange,
                description: "Sold out for now, so they've hopped out of your bag. Tap the bell and we'll ping you the moment they're back."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.outOfStockRows) }
            }
        }
    }

    // MARK: - Not enough left

    private var shortageSection: some View {
        Section {
            ForEach(viewModel.shortageRows) { row in
                noticeRow(row, accessory: { EmptyView() })
            }
        } header: {
            sectionHeader(
                "Not Enough Left",
                icon: "exclamationmark.triangle",
                tint: .orange,
                description: "Going fast. We've matched these to whatever's still on the shelf."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.shortageRows) }
            }
        }
    }

    // MARK: - Costing more

    private var priceIncreaseSection: some View {
        Section {
            ForEach(viewModel.priceIncreaseRows) { row in
                noticeRow(row, accessory: { removeFromBagButton(row.id) })
            }
        } header: {
            sectionHeader(
                "Price Increases",
                icon: "arrow.up.circle",
                tint: .orange,
                description: "Prices went up on these. Rude, we know. Keep them or take them out — your call."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.priceIncreaseRows) }
            }
        }
    }

    // MARK: - Costing less

    /// No Remove. Nobody has ever wanted out of a discount, and offering it here would read as
    /// though something were wrong with it — which is the whole reason this is its own section
    /// rather than half of a "Prices Changed" one asking for a decision about good news.
    private var priceDecreaseSection: some View {
        Section {
            ForEach(viewModel.priceDecreaseRows) { row in
                noticeRow(row, accessory: { EmptyView() })
            }
        } header: {
            sectionHeader(
                "Price Decreases",
                icon: "arrow.down.circle",
                tint: .accentColor,
                description: "Good news, these got cheaper. You're welcome — the lower price is already in your total."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.priceDecreaseRows) }
            }
        }
    }

    /// A shopper who agreed to one price and is being asked for a higher one needs a way out of it
    /// without hunting the bag for the line again. It takes the bell's shape because it stands
    /// where the bell stands and is tapped the same way — once, on the right of a row, and the row
    /// is dealt with — and a capsule reading "Remove" among circles was the odd one out.
    ///
    /// `bag.badge.minus` rather than an X. An X on a notice reads as dismissing the notice, which
    /// is what Okay above it already does, and the two are not the same: one keeps the product at
    /// the new price and the other gives it back. Red because this is the only accessory on the
    /// screen that takes something away.
    private func removeFromBagButton(_ id: ProductID) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            viewModel.didRemoveChangedItem(productId: id)
        } label: {
            Image(systemName: "bag.badge.minus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel("Remove from bag")
    }

    /// One row for every notice, so a shopper reads them the same way wherever they appear. What
    /// differs between sections is the accessory: a bell where waiting is worth something, a way
    /// out where the line is still in the bag at a price nobody agreed to, nothing anywhere else.
    ///
    /// What a row says is only ever what its heading has not already said. Most say nothing at all,
    /// and are a picture and a name — which is what a shopper came to this section to find out.
    private func noticeRow<Accessory: View>(
        _ row: ChangedBagRow,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            thumbnail(url: row.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.name ?? " ")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .redacted(reason: row.name == nil ? .placeholder : [])

                if let move = row.priceMove {
                    priceMove(move)
                }

                if let detail = row.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            accessory()
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
    private func priceMove(_ move: ChangedBagRow.PriceMove) -> some View {
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
    private func oldAmount(_ move: ChangedBagRow.PriceMove) -> some View {
        Text(move.was)
            .strikethrough()
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
    }

    private func direction(_ move: ChangedBagRow.PriceMove) -> some View {
        Image(systemName: move.isCheaper ? "arrow.down" : "arrow.up")
            .font(.caption2.weight(.bold))
            .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)
    }

    private func newAmount(_ move: ChangedBagRow.PriceMove) -> some View {
        Text(move.now)
            .fontWeight(.semibold)
            .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)
            .lineLimit(1)
            .fixedSize()
    }

    // MARK: - The bag itself

    private var bagSection: some View {
        Section {
            ForEach(viewModel.rows) { row in
                bagRow(row)
                    .swipeActions {
                        Button("Remove", role: .destructive) {
                            viewModel.didSwipeToDelete(productId: row.id)
                        }
                    }
            }
        } header: {
            sectionHeader(
                "Your Bag",
                icon: "bag",
                tint: .accentColor,
                description: "The good stuff. Swipe to drop a line, or start over."
            ) {
                Button("Remove All", role: .destructive) { isConfirmingRemoveAll = true }
            }
        }
    }

    private func bagRow(_ row: BagRow) -> some View {
        HStack(spacing: 12) {
            Button {
                navigation.openProductDetails(id: row.id)
            } label: {
                HStack(spacing: 12) {
                    thumbnail(url: row.imageURL)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.name ?? " ")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .redacted(reason: row.name == nil ? .placeholder : [])

                        Text(row.lineTotal.formatted())
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()

                        if row.quantity > 1 {
                            Text("\(row.unitPrice.formatted()) each")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Stepper(
                value: Binding(
                    get: { row.quantity },
                    set: {
                        UISelectionFeedbackGenerator().selectionChanged()
                        viewModel.didChangeQuantity(productId: row.id, quantity: $0)
                    }
                ),
                in: 1...99
            ) {
                Text("\(row.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
        .padding(.vertical, 4)
    }

    // MARK: -

    /// The description sits with the heading and the action rather than under the rows, so a
    /// shopper reads what a section is and what they can do about it before they read its contents
    /// — and does not have to scroll past the rows to find out why they are there.
    private func sectionHeader<Trailing: View>(
        _ title: String,
        icon: String,
        tint: Color,
        description: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(tint)

                Spacer()

                trailing()
                    .font(.footnote.weight(.semibold))
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func thumbnail(url: String?) -> some View {
        if let url {
            KFImage(URL(string: url))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
        }
    }

    private var totalFooter: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total")
                    .font(.headline)
                Text(viewModel.itemCountSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.total?.formatted() ?? "")
                .font(.title3.weight(.bold))
                .monospacedDigit()
        }
        .padding()
        .background(.bar)
    }
}
