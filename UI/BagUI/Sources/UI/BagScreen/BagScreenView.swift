import SwiftUI
import UIKit
import Kingfisher
import Product

public struct BagScreenView: View {
    @ObservedObject var viewModel: BagScreenViewModel
    let navigation: BagNavigation
    let wishlistButton: (ProductID) -> AnyView

    public init(
        viewModel: BagScreenViewModel,
        navigation: BagNavigation,
        wishlistButton: @escaping (ProductID) -> AnyView = { _ in AnyView(EmptyView()) }
    ) {
        self.viewModel = viewModel
        self.navigation = navigation
        self.wishlistButton = wishlistButton
    }

    public var body: some View {
        Group {
            if viewModel.isEmpty && viewModel.removedRows.isEmpty {
                ContentUnavailableView(
                    "Your Bag is Empty",
                    systemImage: "bag",
                    description: Text("Items you add to your bag will appear here.")
                )
            } else {
                List {
                    if !viewModel.removedRows.isEmpty {
                        removedSection
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
    }

    // MARK: - Removed

    private var removedSection: some View {
        Section {
            ForEach(viewModel.removedRows) { removed in
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

                    HStack(spacing: 12) {
                        Button("Okay") {
                            viewModel.didAcknowledgeChange(productId: removed.id)
                        }
                        .buttonStyle(.bordered)

                        Button("Notify Me") {
                            viewModel.didAskToBeNotified(productId: removed.id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                }
                .padding(.vertical, 4)
            }
        } header: {
            sectionHeader("Removed", icon: "xmark.circle")
        } footer: {
            Text("We can't supply these, so they've left your bag.")
        }
    }

    // MARK: - Price changes

    private var priceChangedSection: some View {
        Section {
            ForEach(viewModel.priceChangedRows) { changed in
                changedRow(changed)
            }
        } header: {
            sectionHeader("Prices Changed", icon: "tag")
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
            sectionHeader("Not Enough Left", icon: "exclamationmark.triangle")
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
            sectionHeader("Your Bag", icon: "bag")
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

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
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
