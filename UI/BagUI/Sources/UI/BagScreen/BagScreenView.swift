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
            if viewModel.isEmpty && viewModel.outOfStockRows.isEmpty && viewModel.discontinuedRows.isEmpty {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    if !viewModel.outOfStockRows.isEmpty {
                        outOfStockSection
                    }

                    if !viewModel.discontinuedRows.isEmpty {
                        discontinuedSection
                    }

                    if !viewModel.shortageRows.isEmpty {
                        shortageSection
                    }

                    if !viewModel.priceChangedRows.isEmpty {
                        priceChangedSection
                    }

                    if !viewModel.isEmpty {
                        bagSection
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.isEmpty {
                        totalFooter
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
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
            ForEach(viewModel.outOfStockRows) { removed in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        thumbnail(url: removed.imageURL)

                        wishlistButton(removed.id)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(removed.name ?? " ")
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(2)
                                .redacted(reason: removed.name == nil ? .placeholder : [])
                            Text(removed.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    stockAlertButton(removed.id)
                }
                .padding(.vertical, 4)
            }
        } header: {
            sectionHeader("Out Of Stock", icon: "shippingbox") {
                Button("Okay") { viewModel.didAcceptAll(viewModel.outOfStockRows) }
            }
        } footer: {
            Text("We can't supply these right now, so they've left your bag. Tap the bell and we'll tell you when they're back.")
        }
    }

    // MARK: - Gone for good

    /// No bell. There is nothing to wait for, so the only thing to offer is the wishlist, in case
    /// the shopper wants to remember what it was.
    private var discontinuedSection: some View {
        Section {
            ForEach(viewModel.discontinuedRows) { gone in
                HStack(spacing: 12) {
                    thumbnail(url: gone.imageURL)

                    wishlistButton(gone.id)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(gone.name ?? " ")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .redacted(reason: gone.name == nil ? .placeholder : [])
                        Text(gone.summary)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            sectionHeader("No Longer Available", icon: "xmark.circle") {
                Button("Okay") { viewModel.didAcceptAll(viewModel.discontinuedRows) }
            }
        } footer: {
            Text("The shop has stopped selling these, so they've left your bag.")
        }
    }

    // MARK: - Price changes

    private var priceChangedSection: some View {
        Section {
            ForEach(viewModel.priceChangedRows) { changed in
                changedRow(changed)
            }
        } header: {
            sectionHeader("Prices Changed", icon: "tag") {
                Button("Accept All") { viewModel.didAcceptAll(viewModel.priceChangedRows) }
            }
        } footer: {
            Text("These are still in your bag, at the new price.")
        }
    }

    // MARK: - Not enough left

    private var shortageSection: some View {
        Section {
            ForEach(viewModel.shortageRows) { changed in
                changedRow(changed)
            }
        } header: {
            sectionHeader("Not Enough Left", icon: "exclamationmark.triangle") {
                Button("Accept All") { viewModel.didAcceptAll(viewModel.shortageRows) }
            }
        } footer: {
            Text("These are still in your bag, at the most we can supply.")
        }
    }

    private func changedRow(_ changed: ChangedBagRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                thumbnail(url: changed.imageURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(changed.name ?? " ")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .redacted(reason: changed.name == nil ? .placeholder : [])
                    Text(changed.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button("Okay") {
                    viewModel.didAcknowledgeChange(productId: changed.id)
                }
                .buttonStyle(.bordered)

                Button("Remove", role: .destructive) {
                    viewModel.didRemoveChangedItem(productId: changed.id)
                }
                .buttonStyle(.bordered)
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 4)
    }

    // MARK: - The bag itself

    private var bagSection: some View {
        Section {
            ForEach(viewModel.rows) { row in
                self.row(for: row)
                    .swipeActions {
                        Button("Remove", role: .destructive) {
                            viewModel.didSwipeToDelete(productId: row.id)
                        }
                    }
                    .onAppear {
                        if row.id == viewModel.rows.last?.id {
                            viewModel.onReachEnd()
                        }
                    }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        } header: {
            sectionHeader("Your Bag", icon: "bag") {
                Button("Remove All", role: .destructive) { isConfirmingRemoveAll = true }
            }
        }
    }

    private func row(for row: BagRow) -> some View {
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
                        Text(row.lastKnownPrice.formatted())
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

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
                    .font(.subheadline.weight(.medium))
                    .frame(minWidth: 20)
            }
            .fixedSize()
        }
    }

    // MARK: -

    private func sectionHeader<Trailing: View>(
        _ title: String,
        icon: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            trailing()
                .font(.footnote.weight(.semibold))
                .textCase(nil)
        }
        .textCase(nil)
    }

    @ViewBuilder
    private func thumbnail(url: String?) -> some View {
        if let url {
            KFImage(URL(string: url))
                .resizable()
                .placeholder { ProgressView() }
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .secondarySystemBackground))
                .frame(width: 56, height: 56)
        }
    }

    private var totalFooter: some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            Text(viewModel.total?.formatted() ?? "")
                .font(.headline)
        }
        .padding()
        .background(.bar)
    }
}
