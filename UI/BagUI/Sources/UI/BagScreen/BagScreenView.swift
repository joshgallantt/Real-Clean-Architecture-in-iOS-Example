import SwiftUI
import UIKit
import Kingfisher
import Product

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    @State private var isConfirmingRemoveAll = false

    let navigation: BagNavigation
    let wishlistButton: (ProductID) -> AnyView
    let stockAlertButton: (ProductID) -> AnyView

    public init(
        viewModel: BagScreenViewModel,
        navigation: BagNavigation,
        wishlistButton: @escaping (ProductID) -> AnyView = { _ in AnyView(EmptyView()) },
        stockAlertButton: @escaping (ProductID) -> AnyView = { _ in AnyView(EmptyView()) }
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
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
                    if !viewModel.outOfStockRows.isEmpty { outOfStockSection }
                    if !viewModel.discontinuedRows.isEmpty { discontinuedSection }
                    if !viewModel.shortageRows.isEmpty { shortageSection }
                    if !viewModel.priceChangedRows.isEmpty { priceChangedSection }
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
                description: "We can't supply these right now, so they've left your bag. Tap the bell and we'll tell you when they're back."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.outOfStockRows) }
            }
        }
    }

    // MARK: - Gone for good

    /// No bell. There is nothing to wait for, so the only thing to offer is the wishlist, in case
    /// the shopper wants to remember what it was.
    private var discontinuedSection: some View {
        Section {
            ForEach(viewModel.discontinuedRows) { row in
                noticeRow(row, accessory: { wishlistButton(row.id) })
            }
        } header: {
            sectionHeader(
                "No Longer Available",
                icon: "xmark.circle",
                tint: .secondary,
                description: "The shop has stopped selling these, so they've left your bag."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.discontinuedRows) }
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
                description: "These are still in your bag, at the most we can supply."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.shortageRows) }
            }
        }
    }

    // MARK: - Price changes

    private var priceChangedSection: some View {
        Section {
            ForEach(viewModel.priceChangedRows) { row in
                noticeRow(row) {
                    /// Only where the price went up. A shopper who agreed to one price and is being
                    /// asked for a higher one needs a way out of it without hunting for the line
                    /// again — but nobody has ever wanted out of a discount, and offering it there
                    /// would read as if something were wrong.
                    if row.priceMove?.isCheaper == false {
                        Button("Remove", role: .destructive) {
                            viewModel.didRemoveChangedItem(productId: row.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
        } header: {
            sectionHeader(
                "Prices Changed",
                icon: "tag",
                tint: .accentColor,
                description: "These are still in your bag, at the new price. Remove anything you no longer want at it."
            ) {
                Button("Okay") { viewModel.didAcceptAll(viewModel.priceChangedRows) }
            }
        }
    }

    /// One row for every notice, so a shopper reads them the same way wherever they appear. What
    /// differs between sections is the accessory: a bell where waiting is worth something, a heart
    /// where it is not, nothing where the line is still in the bag.
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

                Text(row.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            accessory()
        }
        .padding(.vertical, 6)
    }

    /// The old amount struck through and the new one coloured, because a shopper takes in "less
    /// than it was" faster than they read it. Down is the accent colour rather than green: green
    /// against red reads as a gain or a loss, and a cheaper price is neither — it is just better.
    private func priceMove(_ move: ChangedBagRow.PriceMove) -> some View {
        HStack(spacing: 6) {
            Text(move.was)
                .strikethrough()
                .foregroundStyle(.secondary)

            Image(systemName: move.isCheaper ? "arrow.down" : "arrow.up")
                .font(.caption2.weight(.bold))
                .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)

            Text(move.now)
                .fontWeight(.semibold)
                .foregroundStyle(move.isCheaper ? Color.accentColor : .orange)
        }
        .font(.subheadline)
        .monospacedDigit()
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
                    .onAppear {
                        if row.id == viewModel.rows.last?.id { viewModel.onReachEnd() }
                    }
            }

            if viewModel.isLoadingMore {
                ProgressView().frame(maxWidth: .infinity)
            }
        } header: {
            sectionHeader(
                "Your Bag",
                icon: "bag",
                tint: .accentColor,
                description: viewModel.itemCountSummary
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
